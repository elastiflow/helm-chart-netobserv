#!/usr/bin/env bash
# Renders the collector address mode and checks the manifests.
set -euo pipefail
cd "$(dirname "$0")/../../.."
chart=charts/netobserv-flow

fail() { echo "render-collectors: $*" >&2; exit 1; }

default=$(helm template netobserv "$chart")
echo "$default" | grep -q 'kind: Deployment' || fail "default render has no Deployment"
if echo "$default" | grep -q 'kind: StatefulSet\|loadBalancerIP:\|externalIPs:'; then
  fail "default render changed the single-Deployment install"
fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
cat >"$tmpdir/collectors.yaml" <<'EOF'
collectors:
  - name: edge-a
    loadBalancerIP: 192.0.2.10
  - name: edge-b
    loadBalancerIP: 192.0.2.11
service:
  loadBalancerSourceRanges:
    - 10.0.0.0/8
EOF

out=$(helm template netobserv "$chart" -f "$tmpdir/collectors.yaml")
echo "$out" | grep -q 'name: netobserv-netobserv-flow-edge-a' || fail "missing edge-a"
echo "$out" | grep -q 'name: netobserv-netobserv-flow-edge-b' || fail "missing edge-b"
echo "$out" | grep -q 'kind: StatefulSet' && fail "rendered a StatefulSet"
echo "$out" | grep -q 'externalIPs:' && fail "rendered externalIPs"
echo "$out" | grep -q 'loadBalancerIP: "192.0.2.10"' || fail "missing edge-a address"
echo "$out" | grep -q 'loadBalancerIP: "192.0.2.11"' || fail "missing edge-b address"
echo "$out" | grep -q 'externalTrafficPolicy: Local' || fail "missing Local policy"
echo "$out" | grep -q 'app.kubernetes.io/component: "edge-a"' || fail "missing edge-a selector"

python3 -c '
import sys
text = sys.stdin.read()
docs = text.split("---")
services = [d for d in docs if "kind: Service" in d]
shared = [d for d in services if "component:" not in d]
pinned = [d for d in services if "component:" in d]
if len(pinned) != 2:
    sys.exit("expected 2 collector services, got %d" % len(pinned))
if len(shared) != 1:
    sys.exit("expected 1 shared service, got %d" % len(shared))
for doc in pinned:
    if "name: api" in doc or "port: 8080" in doc:
        sys.exit("collector service published the API port")
    if "name: netflow" not in doc:
        sys.exit("collector service missing netflow")
    if "type: LoadBalancer" not in doc:
        sys.exit("collector service is not a LoadBalancer")
if "name: netflow" in shared[0]:
    sys.exit("shared service still publishes netflow")
if "name: api" not in shared[0]:
    sys.exit("shared service missing the API port")
deploys = [d for d in docs if "kind: Deployment" in d]
if len(deploys) != 2:
    sys.exit("expected 2 Deployments, got %d" % len(deploys))
for doc in deploys:
    if "replicas: 1" not in doc:
        sys.exit("collector Deployment is not a single replica")
' <<<"$out"

expect_fail() {
  local label=$1
  shift
  if helm template netobserv "$chart" "$@" >/dev/null 2>"$tmpdir/err"; then
    fail "$label was accepted"
  fi
  echo "ok reject: $label"
}

cat >"$tmpdir/bad-name.yaml" <<'EOF'
collectors:
  - name: Edge_A
    loadBalancerIP: 192.0.2.10
EOF
expect_fail "bad name" -f "$tmpdir/bad-name.yaml"

cat >"$tmpdir/dup.yaml" <<'EOF'
collectors:
  - name: edge-a
    loadBalancerIP: 192.0.2.10
  - name: edge-a
    loadBalancerIP: 192.0.2.11
EOF
expect_fail "duplicate name" -f "$tmpdir/dup.yaml"

cat >"$tmpdir/dup-ip.yaml" <<'EOF'
collectors:
  - name: edge-a
    loadBalancerIP: 192.0.2.10
  - name: edge-b
    loadBalancerIP: 192.0.2.10
EOF
expect_fail "duplicate address" -f "$tmpdir/dup-ip.yaml"

cat >"$tmpdir/hpa.yaml" <<'EOF'
autoscaling:
  enabled: true
collectors:
  - name: edge-a
    loadBalancerIP: 192.0.2.10
EOF
expect_fail "autoscaling" -f "$tmpdir/hpa.yaml"

cat >"$tmpdir/noudp.yaml" <<'EOF'
collectors:
  - name: edge-a
    loadBalancerIP: 192.0.2.10
service:
  ports:
    - name: api
      port: 8080
      protocol: TCP
      targetPort: 8080
EOF
expect_fail "no udp port" -f "$tmpdir/noudp.yaml"

echo "render-collectors: ok"
