#!/bin/sh

set -eu

echo "\n📦 Installing ingress-nginx..."

kubectl apply -k resources

echo "\n📦 Installation completed.\n"