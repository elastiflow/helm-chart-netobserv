# NetObserv Flow with OpenSearch using K8s Ingress

- [NetObserv Flow with OpenSearch using K8s Ingress](#netobserv-flow-with-opensearch-using-k8s-ingress)
  - [Overview](#overview)
  - [Install](#install)
  - [Access Dashboards](#access-dashboards)
  - [Hints](#hints)

## Overview

This example deploys NetObserv Flow with OpenSearch as the data platform with API and OTel gRPC inputs exposed. Although local [Kind](https://kind.sigs.k8s.io/) was used for testing, any kubernetes cluster should work if nodes have sufficient resources and don't have any taints that should be tolerated (`tolerations` values may be used).  
This example is intended only for demonstration, testing, or proof-of-concept use, since OpenSearch is deployed in a single-node mode.

Notes on the example deployment:

- [Location in the repository](https://github.com/elastiflow/mermin/tree/beta/docs/deployment/examples/netobserv_os_simple_svc) - `docs/deployment/examples/netobserv_os_simple_svc`
- Namespace used in the example: `elastiflow`.
- Allocatable resources needed (mCPU/MiB):
  - OpenSearch `2000m`/`4000Mi`
  - OpenSearch Dashboards `1000m`/`768M`
  - NetObserv Flow `1000m`/`6000Mi`
- You may optionally customize and use `config.hcl` instead of the default config.

## Install

- Add Helm charts and Deploy
  
  ```sh
  helm repo add netobserv https://elastiflow.github.io/helm-chart-netobserv/
  helm repo add opensearch https://opensearch-project.github.io/helm-charts/
  helm repo update
  kubectl create namespace elastiflow
  helm upgrade -i --wait --timeout 15m -n elastiflow -f examples/flow_os_simple_svc/values.yaml netobserv netobserv/netobserv-os
  ```

- Optionally install `metrics-server` to get metrics if it has not been installed yet

  ```sh
  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.8.0/components.yaml
  # Patch to use insecure TLS, commonly needed on dev local clusters
  kubectl -n kube-system patch deployment metrics-server --type='json' -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
  ```

- Test the API/OTLP endpoints work as expected:

  ```sh
  kubectl -n elastiflow port-forward svc/netobserv-flow 8080:8080 4317:4317

  curl -k "https://127.0.0.1:8080/readyz"
  # 200 - Ready!

  curl -k "https://127.0.0.1:8080/api"
  # 404 page not found

  grpcurl -insecure 127.0.0.1:4317 list
  # grpc.reflection.v1.ServerReflection
  # grpc.reflection.v1alpha.ServerReflection
  # opentelemetry.proto.collector.trace.v1.TraceService
  ```

## Access Dashboards

First, port forward the OpenSearch Dashboards service

```sh
kubectl -n elastiflow port-forward svc/elastiflow-os-dashboards 5601:5601
```

Now you can navigate to `http://localhost:5601/` in your browser to open OpenSearch Dashboards, using `admin`/`Elast1flow!` as the user/password. Select "global tenant", and explore the data.

## Hints

To render and diff Helm templates to Kubernetes manifests, run:

```sh
rm -rf helm_rendered; helm template -n elastiflow -f examples/flow_os_simple_svc/values.yaml --output-dir helm_rendered netobserv netobserv/netobserv-os

# Diff with existing K8s resources
kubectl diff -R -f helm_rendered/
```
