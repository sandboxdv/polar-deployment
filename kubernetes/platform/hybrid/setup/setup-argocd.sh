#!/bin/sh

set -eu

# ------------------------------------------------------------
# Base directory (this script's location)
# ------------------------------------------------------------
BASE_DIR="$1"

# ------------------------------------------------------------
# 0. Enable ingress-nginx snippet annotations (IMPORTANT FIX)
# ------------------------------------------------------------
echo "\n🔧 Enabling ingress-nginx snippet annotations...\n"

# WHY THIS IS NEEDED:
# Ingress uses:
#   nginx.ingress.kubernetes.io/server-snippet
# but ingress-nginx by default blocks snippet annotations
# → without this, ArgoCD will FAIL with admission webhook error
# → result: Ingress is NOT created (Missing / OutOfSync state)

kubectl patch configmap ingress-nginx-controller \
  -n ingress-nginx \
  --type merge \
  -p '{"data":{"allow-snippet-annotations":"true"}}'

echo "\n🔄 Restarting ingress-nginx controller...\n"

kubectl rollout restart deployment ingress-nginx-controller -n ingress-nginx
kubectl rollout status deployment ingress-nginx-controller -n ingress-nginx --timeout=120s

# ------------------------------------------------------------
# 1. Install Argo CD (production script)
# ------------------------------------------------------------
cd "$BASE_DIR/production/argocd"

sh deploy.sh

echo "\n⌛ Waiting for Argo CD to be available...\n"

kubectl wait \
  -n argocd \
  --for=condition=Available \
  deployment \
  --all \
  --timeout=300s

# ------------------------------------------------------------
# 2. Port-forward (no external IP)
# ------------------------------------------------------------
echo "\n🚀 Starting port-forward to Argo CD...\n"

kubectl port-forward svc/argocd-server -n argocd 8080:443 >/dev/null 2>&1 &

PF_PID=$!

sleep 5

echo "\n⛵ Argo CD available at: https://localhost:8080\n"

# ------------------------------------------------------------
# 3. Login to Argo CD CLI
# ------------------------------------------------------------
echo "\n🔑 Logging into Argo CD...\n"

ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)

# WARNING: printing credentials to the console is strictly not
# recommended in production as they may be captured in logs.
echo "\n🔑 Argo CD admin password: $ARGOCD_PASSWORD\n"

argocd login localhost:8080 --insecure \
  --username admin \
  --password "$ARGOCD_PASSWORD"

# ------------------------------------------------------------
# 4. Create Argo CD applications
# ------------------------------------------------------------
echo "\n📦 Creating Argo CD applications...\n"

# Edge Service
argocd app create edge-service \
  --repo https://github.com/sandboxdv/polar-deployment.git \
  --path kubernetes/applications/edge-service/production \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --sync-policy auto \
  --auto-prune

argocd app get edge-service

# Dispatcher Service
argocd app create dispatcher-service \
  --repo https://github.com/sandboxdv/polar-deployment.git \
  --path kubernetes/applications/dispatcher-service/production \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --sync-policy auto \
  --auto-prune

argocd app get dispatcher-service

# Catalog Service
argocd app create catalog-service \
  --repo https://github.com/sandboxdv/polar-deployment.git \
  --path kubernetes/applications/catalog-service/production \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --sync-policy auto \
  --auto-prune

argocd app get catalog-service

# Order Service
argocd app create order-service \
  --repo https://github.com/sandboxdv/polar-deployment.git \
  --path kubernetes/applications/order-service/production \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --sync-policy auto \
  --auto-prune

argocd app get order-service

echo "\n📦 Application services have been successfully deployed"