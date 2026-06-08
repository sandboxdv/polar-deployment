#!/bin/sh

echo "\n🚀 Platform Orchestrator starting...\n"

# ------------------------------------------------------------
# Base directory
# ------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Base directory: $BASE_DIR"

# ------------------------------------------------------------
# 1. Development cluster bootstrap
# ------------------------------------------------------------
cd "$BASE_DIR/development" || exit 1

sh create-cluster.sh

# ------------------------------------------------------------
# 2. Configure ingress
# ------------------------------------------------------------
#cd "$BASE_DIR/production/ingress-nginx" || exit 1
#
#sh deploy.sh

# ------------------------------------------------------------
# 3. Bootstrap ArgoCD
# ------------------------------------------------------------
cd "$BASE_DIR/hybrid/setup"

sh setup-argocd.sh "$BASE_DIR"

# ------------------------------------------------------------
# 4. Create secrets
# ------------------------------------------------------------
cd "$BASE_DIR/hybrid/setup"

sh create-secrets.sh

# ------------------------------------------------------------
# 5. Cluster access info (Ingress base IP)
# ------------------------------------------------------------
echo "\n🌐 Cluster access information:\n"

MINIKUBE_IP=$(minikube ip -p polar 2>/dev/null || echo "N/A")

echo "Minikube IP: http://$MINIKUBE_IP"
echo ""