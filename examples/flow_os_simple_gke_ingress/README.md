# NetObserv Flow with OpenSearch using K8s Ingress

- [NetObserv Flow with OpenSearch using K8s Ingress](#netobserv-flow-with-opensearch-using-k8s-ingress)
  - [Overview](#overview)
  - [Install](#install)
  - [Access](#access)
  - [Hints](#hints)

## Overview

This playbook deploys NetObserv Flow with OpenSearch as the data platform in a GCP GKE cluster with API and OTel gRPC inputs exposed.
This example is intended only for demonstration, testing, or proof-of-concept use, since OpenSearch is deployed in a single-node mode.

Notes on the example deployment:

- This example also assumes you can access internal GCP subnets via a VPN.
- Namespace used in the example: `elastiflow`.
- GKE [node auto-provisioning](https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-provisioning) must be enabled.
- TLS:
  - GCP Load Balancer (ingress) needs the backend with TLS enabled since OTlp input uses gRPC, so a self-signed certificate is used (validity `Not After : Sep 24 10:48:37 2035 GMT`)
  - In order to enable gRPC between client and GCP Load Balancer certificate is also required, same self-signed certificate is used.
  - HTTP (port `80`) is completely disabled on the GCP Load Balancer that is used for the collector (gRPC, REST)
- A GKE internal load balancer is used for the OpenSearch Dashboard ingress.
- Spot instances are used, please tweak affinity and tolerations in the `values.yaml` if needed.

## Install

Change `gke-main-a.us-east1` in the `values.yaml` to your Kubernetes Default Domain (`cluster.local` by default)

```sh
helm repo add netobserv https://elastiflow.github.io/helm-chart-netobserv/
helm repo add opensearch https://opensearch-project.github.io/helm-charts/
helm repo update
helm dependency build elastiflow/netobserv-os
kubectl create namespace elastiflow
helm upgrade -i --wait --timeout 15m -n elastiflow -f examples/flow_os_simple_gke/values.yaml netobserv elastiflow/netobserv-os
```

## Access

First, get the OpenSearch Dashboards address:

```sh
kubectl get ingress elastiflow-os-dashboards -o=jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Now you can navigate to the obtained IP in your browser (assuming you have access to the private network), using `admin`/`Elast1flow!` as the user/password. Select "global tenant", and explore the data.

## Hints

To render and diff Helm templates to Kubernetes manifests, run:

```sh
rm -rf helm_rendered; helm template -n elastiflow -f examples/flow_os_simple_gke/values.yaml --output-dir helm_rendered netobserv elastiflow/netobserv-os

# Diff with existing K8s resources
kubectl diff -R -f helm_rendered/
```
