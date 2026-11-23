#!/usr/bin/env bash
# End-to-end checks against a running deployment.
set -euo pipefail
NS=k8s-demo

kubectl -n "$NS" port-forward svc/k8s-demo 8080:80 >/tmp/pf.log 2>&1 &
PF=$!
trap 'kill $PF 2>/dev/null || true' EXIT
sleep 3

echo "1) service responds and reads ConfigMap + Secret"
curl -fsS localhost:8080/ | tee /dev/stderr | grep -q '"api_key_configured":true'

echo "2) probes are configured"
kubectl -n "$NS" get deploy k8s-demo -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.path}' | grep -q /readyz

echo "3) scale out to 3 replicas"
kubectl -n "$NS" scale deploy/k8s-demo --replicas=3
kubectl -n "$NS" rollout status deploy/k8s-demo --timeout=120s
test "$(kubectl -n "$NS" get deploy k8s-demo -o jsonpath='{.status.readyReplicas}')" = "3"

echo "4) self-healing: delete a pod, deployment replaces it"
POD=$(kubectl -n "$NS" get pods -l component=web -o jsonpath='{.items[0].metadata.name}')
kubectl -n "$NS" delete pod "$POD" --wait=false
sleep 2
kubectl -n "$NS" rollout status deploy/k8s-demo --timeout=120s
kubectl -n "$NS" wait --for=condition=Available deploy/k8s-demo --timeout=120s

echo "5) rolling update to a new config and rollback"
kubectl -n "$NS" set env deploy/k8s-demo WELCOME_MESSAGE="v2"
kubectl -n "$NS" rollout status deploy/k8s-demo --timeout=120s
kubectl -n "$NS" rollout undo deploy/k8s-demo
kubectl -n "$NS" rollout status deploy/k8s-demo --timeout=120s

echo "All cluster tests passed"
