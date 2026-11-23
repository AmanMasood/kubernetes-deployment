#!/usr/bin/env bash
# Build the image and deploy the dev overlay to a local cluster (minikube or kind).
set -euo pipefail
CLUSTER="${CLUSTER:-minikube}"   # minikube | kind
cd "$(dirname "$0")/.."

docker build -t k8s-demo:local app
if [[ "$CLUSTER" == "kind" ]]; then
  kind load docker-image k8s-demo:local
else
  minikube image load k8s-demo:local
fi

kubectl apply -k k8s/overlays/dev
kubectl -n k8s-demo rollout status deploy/k8s-demo --timeout=120s
kubectl -n k8s-demo get pods,svc,ingress,hpa
echo "Try: kubectl -n k8s-demo port-forward svc/k8s-demo 8080:80 && curl localhost:8080"
