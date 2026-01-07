# netObserv Helm Chart

- [netObserv Helm Chart](#netobserv-helm-chart)
  - [Overview](#overview)
  - [Installation](#installation)
  - [Configuration](#configuration)
  - [Upgrade](#upgrade)
    - [`netobserv-flow-0.x.x`/`netobserv-os-0.x.x`](#netobserv-flow-0xxnetobserv-os-0xx)
    - [`netobserv-0.4.14` -\> `netobserv-0.5.x` notes](#netobserv-0414---netobserv-05x-notes)
    - [`netobserv-flow-0.6.0` -\> `netobserv-flow-0.7.x` notes](#netobserv-flow-060---netobserv-flow-07x-notes)
    - [License Setup](#license-setup)
  - [License](#license)

## Overview

The ElastiFlow Unified Flow Collector receives, decodes, transforms, normalizes, translates and enriches network flow records and telemetry sent from network devices and applications using IPFIX, Netflow, sFlow and AWS VPC Flow Logs. The resulting records can be sent to various platforms and services, including:

- Elasticsearch
- Elastic Cloud
- Elastic Cloud Enterprise
- OpenSearch
- AWS OpenSearch Service
- Apache Kafka
- Confluent Platform
- Redpanda
- Splunk
- Cribl Stream

## Installation

```sh
helm repo add netobserv https://elastiflow.github.io/helm-chart-netobserv/
helm repo update
helm install netobserv netobserv/netobserv-flow
```

## Configuration

## Upgrade

### `netobserv-flow-0.x.x`/`netobserv-os-0.x.x`

In order to remove the dependencies from the application chart but still provide an ability for an easy spin-up:

- All dependencies were removed from the `netobserv` chart
- `netobserv` chart is renamed to `netobserv-flow` to align with NetObserv Flow Collector app that is managed by the chart.
- `netobserv-os` chart was introduce to combine NetObserv Flow Collector, OpenSearch, and OpenSearch Dashboards.

In order to migrate from `netobserv-0.5.x` you should be able to install the new chart with a different release name, for example `netobserv-flow`, test the new chart and uninstall old chart release.
Additionally it's a good idea to get the diff between rendered manifests and cluster state to ensure no unintended changes occur:

```sh
rm -rf helm_rendered; helm template -n elastiflow -f examples/flow_os_simple_gke/values.yaml --output-dir helm_rendered netobserv-flow elastiflow/netobserv-flow

# Diff with existing K8s resources
kubectl diff -R -f helm_rendered/
```

### `netobserv-0.4.14` -> `netobserv-0.5.x` notes

Changed values attribute names:

- `secretRef` (in `outputElasticsearch`, `outputOpenSearch`) renamed to `secretName`
- `secretKey` (in `outputElasticsearch`, `outputOpenSearch`) renamed to `secretKeyPassword`
- `caConfigMap` (in `outputElasticsearch.tls`, `outputOpenSearch.tls`, `outputKafka.tls`) renamed to `caConfigMapName`
- `enabled` (in `outputElasticsearch`, `outputElasticsearch.tls`, `outputElasticsearch.ecs`, `outputOpenSearch`, `outputOpenSearch.tls`, `outputOpenSearch.ecs`, `outputKafka`, `outputKafka.tls`) renamed to `enable` in order to be consistent with actual collector env. vars. names.
- `outputElasticsearch` renamed to `outputElasticSearch`

Hint, use `kubectl diff` before upgrade to spot potential issues.

```sh
helm repo update
rm -rf helm_rendered
helm template -n elastiflow -f ${PATH_TO_VALUES} --output-dir helm_rendered netobserv netobserv/netobserv --version netobserv-0.5.0
kubectl diff -R -f helm_rendered
```

### `netobserv-flow-0.6.0` -> `netobserv-flow-0.7.x` notes

- Each `caMountPath` values key was renamed to `caDirName`.
- `outputKafka` values key was removed in order to better align with the existing Ansible Role variables specification ([ref](https://github.com/elastiflow/ansible-collection-netobserv/tree/v0.5.0/roles/netobserv_flow)).

  <details>
  <summary>Migration example</summary>

  Pre `0.7.0` values

  ```yaml
  outputKafka:
    enable: true
    brokers: "192.0.2.11:9092,192.0.2.12:9092,192.0.2.13:9092"
    tls:
      enable: true
      caConfigMapName: "kafka-ca"
      caConfigMapKey: "ca.crt"
      caMountPath: "/etc/ssl"
      caFileName: "ca.crt"

  ```

  `>= 0.7.0` values

  ```yaml
  env:
    - name: EF_OUTPUT_KAFKA_ENABLE
      value: 'true'
    - name: "EF_OUTPUT_KAFKA_BROKERS"
      value: "192.0.2.11:9092,192.0.2.12:9092,192.0.2.13:9092"
    - name: EF_OUTPUT_KAFKA_TLS_ENABLE
      value: 'true'
    - name: "EF_OUTPUT_KAFKA_TLS_CA_CERT_FILEPATH"
      value: '/etc/ssl/ca.crt'

  extraVolumeMounts:
    - name: kafka-ca
      mountPath: /etc/ssl
      readOnly: true

  extraVolumes:
    - name: kafka-ca
      configMap:
        name: kafka-ca
        items:
          - key: ca.crt
            path: ca.crt
  ```

  </details>

Hint, use `kubectl diff` before upgrade to spot potential issues.

```sh
helm repo update
rm -rf helm_rendered
helm template -n ${NAMESPACE}$ -f ${PATH_TO_VALUES} --output-dir helm_rendered netobserv netobserv/netobserv-flow --version 0.7.0
kubectl diff -R -f helm_rendered
```

### License Setup

To configure an ElastiFlow license key, you can add the following to your `values.yaml`:

```yaml
license:
  createSecret: true
```

Then make sure to use helm's `set` option to configure the license key when installing the chart. For example:

```sh
helm install netobserv netobserv/netobserv-flow \
  --set license.licenseKey="licensekeygoeshere"
```

For additional kubernetes configuration information, please refer to the comments in the [default values file](./charts/netobserv-flow/values.yaml).

For additional environment configurations, please refer to the [configuration reference guide](https://docs.elastiflow.com/docs/config_ref/).

## License

This project is licensed under the [Apache 2.0 License](./LICENSE).
