{{/*
Expand the name of the chart.
*/}}
{{- define "netobserv.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "netobserv.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "netobserv.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "netobserv.labels" -}}
helm.sh/chart: {{ include "netobserv.chart" . }}
{{ include "netobserv.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- range $k, $v := .Values.commonLabels }}
{{ $k }}: {{ $v | quote }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "netobserv.selectorLabels" -}}
app.kubernetes.io/name: {{ include "netobserv.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "netobserv.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "netobserv.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/* Determine if volumes need to be created */}}
{{- define "volumesEnabled" -}}
  {{- or
    .Values.maxmind.asnEnabled
    .Values.maxmind.geoipEnabled
    (and .Values.outputElasticSearch.tls.enable (not (eq .Values.outputElasticSearch.tls.caConfigMapName "")))
    (and .Values.outputOpenSearch.tls.enable (not (eq .Values.outputOpenSearch.tls.caConfigMapName "")))
    (not (empty .Values.extraVolumes))
  -}}
{{- end -}}

{{/* Determine if volumeMounts need to be created */}}
{{- define "volumeMountsEnabled" -}}
  {{- or
    .Values.maxmind.asnEnabled
    .Values.maxmind.geoipEnabled
    (and .Values.outputElasticSearch.tls.enable (not (eq .Values.outputElasticSearch.tls.caConfigMapName "")))
    (and .Values.outputOpenSearch.tls.enable (not (eq .Values.outputOpenSearch.tls.caConfigMapName "")))
    (not (empty .Values.extraVolumeMounts))
  -}}
{{- end -}}

{{/* Deployment and Service name for one named collector, or the single Deployment. */}}
{{- define "netobserv.workloadName" -}}
{{- if .name -}}
{{- printf "%s-%s" (include "netobserv.fullname" .root) .name -}}
{{- else -}}
{{- include "netobserv.fullname" .root -}}
{{- end -}}
{{- end -}}

{{/* Reject collector settings that would not pin one address to one pod. */}}
{{- define "netobserv.validateCollectors" -}}
{{- if .Values.collectors -}}
{{- if not (kindIs "slice" .Values.collectors) -}}
{{- fail "collectors must be a list" -}}
{{- end -}}
{{- if .Values.autoscaling.enabled -}}
{{- fail "collectors cannot be used with autoscaling.enabled" -}}
{{- end -}}
{{- $udp := list -}}
{{- range .Values.service.ports -}}
{{- if eq .protocol "UDP" -}}
{{- $udp = append $udp .protocol -}}
{{- end -}}
{{- end -}}
{{- if not $udp -}}
{{- fail "collectors requires at least one UDP service port" -}}
{{- end -}}
{{- $names := dict -}}
{{- $ips := dict -}}
{{- range .Values.collectors -}}
{{- if not (kindIs "map" .) -}}
{{- fail "collectors entries must be objects with name and loadBalancerIP" -}}
{{- end -}}
{{- if not .name -}}
{{- fail "collectors[].name is required" -}}
{{- end -}}
{{- if not (regexMatch "^[a-z0-9]([-a-z0-9]*[a-z0-9])?$" .name) -}}
{{- fail (printf "collector name %q must be a lowercase DNS label" .name) -}}
{{- end -}}
{{- if not .loadBalancerIP -}}
{{- fail (printf "collector %s requires loadBalancerIP" .name) -}}
{{- end -}}
{{- if not (kindIs "string" .loadBalancerIP) -}}
{{- fail (printf "collector %s loadBalancerIP must be a string" .name) -}}
{{- end -}}
{{- $full := printf "%s-%s" (include "netobserv.fullname" $) .name -}}
{{- if gt (len $full) 63 -}}
{{- fail (printf "collector name %s makes %s longer than 63 characters" .name $full) -}}
{{- end -}}
{{- if hasKey $names .name -}}
{{- fail (printf "duplicate collector name %s" .name) -}}
{{- end -}}
{{- if hasKey $ips .loadBalancerIP -}}
{{- fail (printf "duplicate collector address %s" .loadBalancerIP) -}}
{{- end -}}
{{- $_ := set $names .name "1" -}}
{{- $_ := set $ips .loadBalancerIP "1" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* UDP service ports. These are the flow listeners pinned to one pod. */}}
{{- define "netobserv.udpServicePorts" -}}
{{- $out := list -}}
{{- range .Values.service.ports -}}
{{- if eq .protocol "UDP" -}}
{{- $out = append $out . -}}
{{- end -}}
{{- end -}}
{{- toYaml $out -}}
{{- end -}}

{{/*
Non-UDP service ports for the shared Service.
shortcut: if every service port is UDP, those ports stay on the shared Service and can still be balanced. Add a TCP port when that matters.
*/}}
{{- define "netobserv.nonUdpServicePorts" -}}
{{- $out := list -}}
{{- range .Values.service.ports -}}
{{- if ne .protocol "UDP" -}}
{{- $out = append $out . -}}
{{- end -}}
{{- end -}}
{{- if not $out -}}
{{- $out = .Values.service.ports -}}
{{- end -}}
{{- toYaml $out -}}
{{- end -}}

{{/* Define ElasticSearch credentials secret name */}}
{{- define "netobserv.elasticSearchCredentialsSecretName" -}}
  {{- if (.Values.outputElasticSearch.secretName | empty) -}}
  {{ include "netobserv.fullname" . }}-es-creds
  {{- else -}}
  {{ .Values.outputElasticSearch.secretName }}
  {{- end -}}
{{- end -}}

{{/* Define OpenSearch credentials secret name */}}
{{- define "netobserv.openSearchCredentialsSecretName" -}}
  {{- if (.Values.outputOpenSearch.secretName | empty) -}}
  {{ include "netobserv.fullname" . }}-os-creds
  {{- else -}}
  {{ .Values.outputOpenSearch.secretName }}
  {{- end -}}
{{- end -}}

{{/* Define OpenSearch Dashboards dashboards import command */}}
{{- define "netobserv.osDashboardsImportCMD" -}}
{{- $insecure := .Values.outputOpenSearch.dashboards.tls.validate_certs | ternary "-k" "" -}}
{{- $headers := `-H "osd-xsrf: true"` -}}
{{- with .Values.outputOpenSearch.dashboards.securityTenant -}}
{{- $headers = printf `%s -H "securitytenant: %s"` $headers . -}}
{{- end -}}
{{- $form := "--form file=@/tmp/dashboards.ndjson" -}}
curl -XPOST -f {{ $insecure }} {{ $headers }} {{ $form }} -u "${EF_OUTPUT_OPENSEARCH_USERNAME}:${EF_OUTPUT_OPENSEARCH_PASSWORD}" "{{ .Values.outputOpenSearch.dashboards.dashboards_url }}/api/saved_objects/_import?overwrite={{ .Values.outputOpenSearch.dashboards.override }}"
{{- end -}}

{{/* Define ElasticSearch Dashboards dashboards import command */}}
{{- define "netobserv.esDashboardsImportCMD" -}}
{{- $insecure := .Values.outputElasticSearch.dashboards.tls.validate_certs | ternary "-k" "" -}}
{{- $headers := `-H "kbn-xsrf: true"` -}}
{{- with .Values.outputElasticSearch.dashboards.securityTenant -}}
{{- $headers = printf `%s -H "securitytenant: %s"` $headers . -}}
{{- end -}}
{{- $form := "--form file=@/tmp/dashboards.ndjson" -}}
curl -XPOST -f {{ $insecure }} {{ $headers }} {{ $form }} -u "${EF_OUTPUT_ELASTICSEARCH_USERNAME}:${EF_OUTPUT_ELASTICSEARCH_PASSWORD}" "{{ .Values.outputElasticSearch.dashboards.dashboards_url }}/api/saved_objects/_import?overwrite={{ .Values.outputElasticSearch.dashboards.override }}"
{{- end -}}
