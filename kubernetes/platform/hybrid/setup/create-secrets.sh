#!/bin/sh

set -eu

echo "\n🔐 Creating Kubernetes secrets...\n"

# ------------------------------------------------------------
# Redis
# ------------------------------------------------------------
echo "\n📦 Creating Redis secret..."

kubectl delete secret polar-redis-credentials --ignore-not-found

kubectl create secret generic polar-redis-credentials \
  --from-literal=spring.redis.host=http://polar-redis


# ------------------------------------------------------------
# Keycloak
# ------------------------------------------------------------
echo "\n📦 Creating Keycloak secrets..."

kubectl delete secret polar-keycloak-client-credentials --ignore-not-found

kubectl create secret generic polar-keycloak-client-credentials \
  --from-literal=spring.security.oauth2.client.registration.keycloak.client-id=edge-service \
  --from-literal=spring.security.oauth2.client.registration.keycloak.client-secret=polar-keycloak-secret \
  --from-literal=spring.security.oauth2.client.registration.keycloak.scope=openid,roles

kubectl delete secret keycloak-issuer-client-secret --ignore-not-found

kubectl create secret generic keycloak-issuer-client-secret \
  --from-literal=spring.security.oauth2.client.provider.keycloak.issuer.uri=http://polar-keycloak/realms/PolarBookshop

kubectl delete secret keycloak-issuer-resourceserver-secret --ignore-not-found

kubectl create secret generic keycloak-issuer-resourceserver-secret \
  --from-literal=spring.security.oauth2.resourceserver.jwt.issuer.uri=http://polar-keycloak/realms/PolarBookshop


# ----------------------------
# RabbitMQ
# ----------------------------
echo "\n📦 Creating RabbitMQ credentials secret..."

kubectl delete secret polar-rabbitmq-credentials --ignore-not-found

kubectl create secret generic polar-rabbitmq-credentials \
  --from-literal=spring.rabbitmq.host=polar-rabbitmq

# ----------------------------
# PostgreSQL
# ----------------------------
echo "📦 Creating PostgreSQL secrets..."

kubectl delete secret polar-postgres-catalog-credentials --ignore-not-found

kubectl create secret generic polar-postgres-catalog-credentials \
  --from-literal=spring.datasource.username=user \
  --from-literal=spring.datasource.password=password

kubectl delete secret polar-postgres-order-credentials --ignore-not-found

kubectl create secret generic polar-postgres-order-credentials \
  --from-literal=spring.datasource.username=user \
  --from-literal=spring.datasource.password=password


echo "\n✅ Development secrets successfully created.\n"