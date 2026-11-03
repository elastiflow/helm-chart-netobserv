# netObserv Helm Chart

- [netObserv Helm Chart](#netobserv-helm-chart)
  - [Overview](#overview)
  - [Installation](#installation)
  - [Configuration](#configuration)
    - [License Setup](#license-setup)
    - [Prometheus Operator ServiceMonitor](#prometheus-operator-servicemonitor)
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
helm install netobserv netobserv/netobserv
```

## Configuration

### License Setup

To configure an ElastiFlow license key, you can add the following to your `values.yaml`:

```yaml
license:
  createSecret: true
```

Then make sure to use helm's `set` option to configure the license key when installing the chart. For example:

```sh
helm install netobserv netobserv/netobserv \
  --set license.licenseKey="licensekeygoeshere"
```

For additional kubernetes configuration information, please refer to the comments in the [default values file](./charts/netobserv/values.yaml).

For additional environment configurations, please refer to the [configuration reference guide](https://docs.elastiflow.com/flowcoll/configuration).

### Dedicated collector addresses

Raising `replicaCount` puts every pod behind one Service. A load balancer then spreads each device's flows across collectors, and a collector can miss the templates it needs to decode that device.

Set `collectors` to one IP per collector. The chart replaces the Deployment with a StatefulSet (one pod per address) and a Service that selects only that pod. Point each device at one address. Leave `collectors` empty to keep the single Deployment.

```yaml
collectors:
  - 192.0.2.10
  - 192.0.2.11
```

List order is the pod identity, so do not reorder it. This does not combine with `autoscaling`. The shared Service still selects every pod. Those per-address Services use `externalTrafficPolicy: Local` unless you set `service.externalTrafficPolicy`, so the device source address is kept. A packet that lands on a node without that pod is dropped. With the default `ClusterIP` Service, route each address to the node running that pod. When `service.type` is `LoadBalancer`, each address is that pod's `loadBalancerIP` instead.

### Prometheus Operator ServiceMonitor

If you use the Prometheus Operator, you can enable a `ServiceMonitor` to scrape metrics from the flow collector Service.

Quick start:

```yaml
serviceMonitor:
  enabled: true
  # If your Prometheus Operator selects ServiceMonitors by label, add it here
  labels:
    release: prometheus
  # Scrape the Service's named port
  portName: api
  path: /metrics
  interval: 30s
  scrapeTimeout: 10s
```

## License

This project is licensed under the [Apache 2.0 License](./LICENSE).
