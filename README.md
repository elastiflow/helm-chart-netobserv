# netObserv Helm Chart

- [Overview](#overview)
- [Installation](#installation)
- [Configuration](#configuration)

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
