#!/bin/bash

# Set variables
export PROJECT_ID="YOUR_PROJECT_ID"
export ZONE="us-central1-a"
export CLUSTER_NAME="myapp-cluster"

# Authenticate with GCP
gcloud auth login
gcloud config set project $PROJECT_ID

# Create GKE cluster if not exists
if ! gcloud container clusters describe $CLUSTER_NAME --zone $ZONE &> /dev/null; then
    echo "Creating GKE cluster..."
    gcloud container clusters create $CLUSTER_NAME \
        --zone $ZONE \
        --num-nodes=3 \
        --enable-autoscaling \
        --min-nodes=2 \
        --max-nodes=10 \
        --machine-type=e2-standard-2
fi

# Get credentials
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE

# Create namespace
kubectl create namespace myapp

# Apply configurations
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/pv-pvc.yaml
kubectl apply -k k8s/

# Setup monitoring
bash scripts/setup-monitoring.sh

# Setup ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.0/deploy/static/provider/cloud/deploy.yaml

# Expose application
kubectl apply -f k8s/ingress.yaml

echo "Deployment complete!"
echo "Get external IP: kubectl get ingress -n myapp"


# Assign roles to GitHub Actions SA
# Create key for GitHub Actions
gcloud iam service-accounts keys create github-actions-key.json \
  --iam-account=github-actions-sa@maximc-gcp.iam.gserviceaccount.com

# Create key for local development
gcloud iam service-accounts keys create cluster-admin-key.json \
  --iam-account=cluster-admin-sa@maximc-gcp.iam.gserviceaccount.com

# Secure the keys (IMPORTANT!)
chmod 600 github-actions-key.json cluster-admin-key.json