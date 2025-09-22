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

{{/*
Determine if volumes need to be created
*/}}
{{- define "volumesEnabled" -}}
  {{- or
    .Values.maxmind.asnEnabled
    .Values.maxmind.geoipEnabled
    (and .Values.outputKafka.tls.enable (not (eq .Values.outputKafka.tls.caConfigMapName "")))
    (and .Values.outputElasticSearch.tls.enable (not (eq .Values.outputElasticSearch.tls.caConfigMapName "")))
    (and .Values.outputOpenSearch.tls.enable (not (eq .Values.outputOpenSearch.tls.caConfigMapName "")))
    (not (empty .Values.extraVolumes))
  -}}
{{- end -}}

{{/*
Determine if volumeMounts need to be created
*/}}
{{- define "volumeMountsEnabled" -}}
  {{- or
    .Values.maxmind.asnEnabled
    .Values.maxmind.geoipEnabled
    (and .Values.outputKafka.tls.enable (not (eq .Values.outputKafka.tls.caConfigMapName "")))
    (and .Values.outputElasticSearch.tls.enable (not (eq .Values.outputElasticSearch.tls.caConfigMapName "")))
    (and .Values.outputOpenSearch.tls.enable (not (eq .Values.outputOpenSearch.tls.caConfigMapName "")))
    (not (empty .Values.extraVolumeMounts))
  -}}
{{- end -}}

{{/*
Determine ElasticSearch credentials secret name
*/}}
{{- define "netobserv.elasticSearchCredentialsSecretName" -}}
  {{- if (.Values.outputElasticSearch.secretName | empty) -}}
  {{ include "netobserv.fullname" . }}-es-creds
  {{- else -}}
  {{ .Values.outputElasticSearch.secretName }}
  {{- end -}}
{{- end -}}

{{/*
Determine OpenSearch credentials secret name
*/}}
{{- define "netobserv.openSearchCredentialsSecretName" -}}
  {{- if (.Values.outputOpenSearch.secretName | empty) -}}
  {{ include "netobserv.fullname" . }}-os-creds
  {{- else -}}
  {{ .Values.outputOpenSearch.secretName }}
  {{- end -}}
{{- end -}}
