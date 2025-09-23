# NetObserv Flow with OpenSearch

- [NetObserv Flow with OpenSearch](#netobserv-flow-with-opensearch)
  - [Overview](#overview)
  - [Install](#install)
  - [Access](#access)
  - [Hints](#hints)

## Overview

This playbook deploys NetObserv Flow with OpenSearch as the data platform in the GCP GKE clusters.  
Intended for demonstration, testing, or proof-of-concept use only since OpenSearch is deployed in a single node mode.

Notes on the example deployment:

- GKE [node auto-provisioning](https://cloud.google.com/kubernetes-engine/docs/how-to/node-auto-provisioning) must be enabled.
- Namespace used in the example: `elastiflow`
- GKE internal load balancer is used for the OpenSearch Dashboard ingress
  Assumed you have access to internal GCP subnets via VPN
- Spot instances are used, please tweak affinity and tolerations in the `values.yaml` if needed.

<!-- TODO: use remote chart everywhere in the doc -->

## Install

```sh
helm repo add opensearch https://opensearch-project.github.io/helm-charts/
helm dependency build charts/netobserv
kubectl create namespace elastiflow
helm upgrade -i --wait --timeout 15m -n elastiflow -f examples/flow_os_simple_gke/values.yaml netobserv charts/netobserv
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
rm -rf helm_rendered/netobserv; helm template -n elastiflow -f examples/flow_os_simple_gke/values.yaml --output-dir helm_rendered netobserv charts/netobserv

# Diff with existing K8s resources
kubectl diff -R -f helm_rendered/netobserv/
```
