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

Set `collectors` to one named collector per address. Each entry is its own Deployment and a LoadBalancer Service that selects only that Deployment. `externalTrafficPolicy` is `Local`, so the collector sees the device source address as long as the load balancer sends traffic to the node running that pod. Point each device at one address. Leave `collectors` empty to keep the single Deployment.

```yaml
collectors:
  - name: edge-a
    loadBalancerIP: 192.0.2.10
  - name: edge-b
    loadBalancerIP: 192.0.2.11
```

`name` is the identity. Reordering the list does not move an address. This does not combine with `autoscaling`, and `service.ports` must include a UDP port. Those UDP ports are only on the per-collector Services. The shared Service keeps the TCP ports, including the API, and still selects every pod. The address comes from a cloud load balancer or MetalLB. `loadBalancerIP` asks for a static address. `service.loadBalancerSourceRanges` applies to each of these Services.

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
