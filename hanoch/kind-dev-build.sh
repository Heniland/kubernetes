#!/bin/bash

# Custom Kind Node Image Builder for Kubernetes Development
# ---------------------------------------------------------

# Configuration
MIN_GO_VERSION="1.23.4"
KUBERNETES_SOURCE_DIR="${GOPATH}/src/k8s.io/kubernetes"
KUBE_GIT_VERSION="v1.32.0-hanoch-$(date +%Y%m%d%H%M)"
KIND_IMAGE_TAG="kindest/node:hanoch-$(date +%Y%m%d)"
CLUSTER_NAME="hanoch-cluster"

# --- 1. System Requirements Checks ---
echo "--- 1. Checking System Requirements ---"

# Required Binaries
command -v docker &> /dev/null || { echo "Error: docker is not installed. Please install docker."; exit 1; }
docker info &> /dev/null || { echo "Error: docker daemon is not running. Please start the docker service."; exit 1; }
command -v make &> /dev/null || { echo "Error: make is not installed. Please install make."; exit 1; }
command -v kind &> /dev/null || { echo "Error: kind is not installed. Please install kind."; exit 1; }

# Go Version
command -v go &> /dev/null || { echo "Error: Go is not installed. Please install Go."; exit 1; }
CURRENT_GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
if [[ $(printf '%s\n' "$MIN_GO_VERSION" "$CURRENT_GO_VERSION" | sort -V | head -n 1) == "$MIN_GO_VERSION" ]]; then
  echo "Go version ${CURRENT_GO_VERSION} is compatible."
else
  echo "Error: Go version is too old. Minimum required version is ${MIN_GO_VERSION}. Current version is ${CURRENT_GO_VERSION}."
  exit 1
fi

# GOPATH
if [ -z "${GOPATH}" ]; then
  echo "Error: GOPATH is not set. Please set the GOPATH environment variable."
  exit 1
fi

# Kubernetes Source Directory
if [ ! -d "${KUBERNETES_SOURCE_DIR}" ]; then
  echo "Error: Kubernetes source directory '${KUBERNETES_SOURCE_DIR}' does not exist. Please clone the Kubernetes repository."
  exit 1
fi

# --- 2. Building Kubernetes ---
echo "--- 2. Building Kubernetes Binaries ---"
make || { echo "Error: Kubernetes build failed. Check the build logs."; exit 1; }


# --- 3. Building Kind Image ---
echo "--- 3. Building Kind Node Image ---"
export KUBE_GIT_VERSION="${KUBE_GIT_VERSION}"
kind build node-image --image "${KIND_IMAGE_TAG}" || { echo "Error: Kind node image build failed."; exit 1; }


# --- 4. Creating Kind Cluster ---
echo "--- 4. Creating Kind Cluster ---"
kind create cluster --name "${CLUSTER_NAME}" --image "${KIND_IMAGE_TAG}" || { echo "Error: Kind cluster creation failed."; exit 1; }


# --- 5. Verifying Cluster ---
echo "--- 5. Verifying Cluster ---"
echo "Cluster status:"
kubectl get nodes -o wide
kubectl version

# --- 6. Summary ---
echo "Cluster '${CLUSTER_NAME}' created successfully!"
echo "Kubernetes version: ${KUBE_GIT_VERSION}"
echo "Kind node image: ${KIND_IMAGE_TAG}"
