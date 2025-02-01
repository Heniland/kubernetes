#!/bin/bash

# Custom Kind Node Image Builder for Kubernetes Development
# ---------------------------------------------------------

# Configuration
KUBERNETES_SOURCE_DIR="${GOPATH}/src/k8s.io/kubernetes"
KUBE_GIT_VERSION="v1.32.0-hanoch-$(date +%Y%m%d%H%M)"
KIND_IMAGE_TAG="kindest/node:hanoch-$(date +%Y%m%d)"

# Step 1: Build Kubernetes (optional but recommended)
echo "Building Kubernetes binaries..."
make

# Step 2: Build Kind node image with custom version
echo "Building Kind node image..."
export KUBE_GIT_VERSION="${KUBE_GIT_VERSION}"
kind build node-image --image "${KIND_IMAGE_TAG}"

# Step 3: Create cluster with the new image
echo "Creating Kind cluster..."
kind create cluster --name hanoch-cluster --image "${KIND_IMAGE_TAG}"

# Step 4: Verify cluster
echo "Cluster status:"
kubectl get nodes
kubectl version
