#!/bin/bash

set -e 

## Get the top-level directory of the Git repository
TOP_LEVEL=$(git rev-parse --show-toplevel)
export TOP_LEVEL

# Define variables
NAMESPACE="argocd"
RELEASE_NAME="argocd"
CHART_DIR="$TOP_LEVEL/charts"
PORT_LOCAL=8080
PORT_REMOTE=443
AWS_REGION="us-gov-east-1"
AWS_ACCOUNT_ID="283857190015"

## Prompt user for AWS Credentials
read -p "Enter your AWS Access Key ID: " AWS_ACCESS_KEY_ID
read -s -p "Enter your AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
echo ""
export AWS_REGION
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION

# Function to check if Minikube is running
is_minikube_running() {
  minikube status >/dev/null 2>&1
}

# Function to wait for Minikube to be ready
wait_for_minikube() {
  echo "Waiting for Minikube to be ready..."
  until kubectl get nodes >/dev/null 2>&1; do
    echo "Waiting for Kubernetes API..."
    sleep 5
  done
  echo "Minikube is up."
}

# Start Minikube if it's not running
if is_minikube_running; then
  echo "Minikube is already running."
else
  echo "Starting Minikube..."
  minikube start --cpus=6 --memory=10g --disk-size=50g --driver=docker
  wait_for_minikube
fi

# Create namespace
echo "Creating namespace: $NAMESPACE"
kubectl create ns "$NAMESPACE" || echo "Namespace $NAMESPACE already exists"

# Change directory to Helm chart path
cd "$CHART_DIR" || { echo "Chart directory not found: $CHART_DIR"; exit 1; }

# Helm upgrade/install
echo "Installing or upgrading Helm chart..."
helm upgrade --install -i "$RELEASE_NAME" --namespace "$NAMESPACE" \
  --set redis.exporter.enabled=true \
  --set redis.metrics.enabled=true \
  --set server.metrics.enabled=true \
  --set controller.metrics.enabled=true argo-cd

# Wait for the ArgoCD pod to be ready
echo "Waiting for ArgoCD server pod to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n "$NAMESPACE"

# Retrieve initial admin password
echo "Retrieving initial admin password..."
ADMIN_PASSWORD=$(kubectl -n "$NAMESPACE" get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Start port forwarding in the background
echo "Starting port-forwarding to https://localhost:$PORT_LOCAL/"
kubectl port-forward svc/argocd-server -n "$NAMESPACE" "$PORT_LOCAL":"$PORT_REMOTE" >/dev/null 2>&1 &
PORT_FORWARD_PID=$!
sleep 5  # Give port-forward time to start

# Login using ArgoCD CLI
echo "Logging in with ArgoCD CLI..."
argocd login localhost:$PORT_LOCAL --username admin --password "$ADMIN_PASSWORD" --insecure

cat <<EOF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ArgoCD is accessible at: https://localhost:$PORT_LOCAL/
ArgoCD Default Username: admin
ArgoCD Default Password: $ADMIN_PASSWORD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
EOF

# Create Argocd Repo
kubectl apply -f "$TOP_LEVEL/argocd/argocd-repositories"

## Create Argocd Project
kubectl apply -f "$TOP_LEVEL/argocd/argocd-projects"

## pre-install-chart
kubectl apply -f "$TOP_LEVEL/argocd/argocd-applications/development/pre-install-chart.yaml"
argocd app wait pre-install-chart --timeout 300
echo "Application pre-install-chart is now fully synchronized and healthy. Proceeding with the rest of the script."

## Reloader
kubectl apply -f "$TOP_LEVEL/argocd/argocd-applications/development/Reloader.yaml"

## external-secrets
kubectl apply -f "$TOP_LEVEL/argocd/argocd-applications/development/external-secrets.yaml"
argocd app wait external-secrets --timeout 300
echo "Application external-secrets is now fully synchronized and healthy. Proceeding with the rest of the script."

deployments=(
  "external-secrets"
  "external-secrets-cert-controller"
  "external-secrets-webhook"
)
namespace="external-secrets"
wait_for_deployment() {
  local deployment=$1
  echo "Waiting for deployment '$deployment' in namespace '$namespace' to become available..."
  kubectl wait --for=condition=available --timeout=300s deployment/"$deployment" -n "$namespace"
}
for deployment in "${deployments[@]}"; do
  wait_for_deployment "$deployment"
done
echo "All External Secrets Operator deployments are now available. Proceeding with the rest of the script."

## Create AWS Credentials Secrets for various namespaces
NAMESPACES=(
  external-secrets
  xyz-cdm-processor
  xyz-quality-cdm-processor
  abc-cdm-processor
  abc-quality-cdm-processor
  cdm-dictionary-connector
)

for ns in "${NAMESPACES[@]}"; do
  if kubectl get secret aws-credentials --namespace "$ns" >/dev/null 2>&1; then
    echo "Secret 'aws-credentials' already exists in namespace '$ns'. Skipping creation."
  else
    echo "Creating secret 'aws-credentials' in namespace '$ns'."
    kubectl create secret generic aws-credentials \
      --namespace "$ns" \
      --from-literal=AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
      --from-literal=AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
      --from-literal=AWS_REGION="$AWS_REGION"
  fi
done

for ns in "${NAMESPACES[@]}"; do
  echo "Verifying secret in namespace: $ns"
  kubectl get secret aws-credentials --namespace "$ns"
done


# ## Apply ClusterSecretStore and ExternalSecrets
kubectl apply -f  $TOP_LEVEL/external-secrets/cluster-secret-store-local-development.yaml
# sleep 5

kubectl apply -f  $TOP_LEVEL/argocd/argocd-applications/development/cdm-cfk-secrets.yaml
kubectl apply -f $TOP_LEVEL/argocd/argocd-applications/development/cdm-data-pipeline-abc-secrets.yaml
kubectl apply -f  $TOP_LEVEL/argocd/argocd-applications/development/cdm-data-pipeline-xyz-secrets.yaml
sleep 20

## Check if ExternalSecrets were  createds
kubectl get ExternalSecret -A
## Check if ClusterSecretStore was created
kubectl get ClusterSecretStore -A

## Create Kubernetes pull secrets for ECR
NAMESPACES=(
  abc-armis-connector
  abc-armis-processor
  abc-cdm-processor
  abc-quality-cdm-processor
  abc-elastic-sink
  abc-quality-elastic-sink
  xyz-axonius-connector
  xyz-axonius-processor
  xyz-cdm-processor
  xyz-quality-cdm-processor
  xyz-elastic-sink
  xyz-quality-elastic-sink
  cdm-dictionary-connector
)
create_image_pull_secret_if_absent() {
  local ns=$1
  local secret_name="ecr-secret"

  if kubectl get secret "$secret_name" --namespace "$ns" >/dev/null 2>&1; then
    echo "Secret '$secret_name' already exists in namespace '$ns'. Skipping creation."
  else
    echo "Creating image pull secret '$secret_name' in namespace '$ns'."
    kubectl create secret docker-registry "$secret_name" \
      --docker-server="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com" \
      --docker-username=AWS \
      --docker-password="$(aws ecr get-login-password --region $AWS_REGION)" \
      --namespace "$ns"
  fi
}

for ns in "${NAMESPACES[@]}"; do
  create_image_pull_secret_if_absent "$ns"
done

for ns in "${NAMESPACES[@]}"; do
  echo "Verifying secret in namespace: $ns"
  kubectl get secret ecr-secret --namespace "$ns"
done

## Deploy Confluent Operator
cd $TOP_LEVEL/charts
helm upgrade --install confluent-operator \
  confluentinc/confluent-for-kubernetes \
  --set kRaftEnabled=true \
  --set fipsmode=true \
  --namespace cdm-kafka
kubectl wait --for=condition=available --timeout=300s deployment/confluent-operator -n cdm-kafka

## Deploy LDAP
cd $TOP_LEVEL/charts
helm upgrade --install \
  -f openldap/ldaps-rbac.yaml \
  cdm-ldap openldap \
  --namespace cdm-kafka

## Deploy CFK
kubectl apply -f  $TOP_LEVEL/argocd/argocd-applications/development/cdm-cfk.yaml
sleep 600

## Deploy cdm-data-pipeline-xyz
kubectl apply -f  $TOP_LEVEL/argocd/argocd-applications/development/cdm-data-pipeline-xyz.yaml

## Deploy cdm-data-pipeline-abc
# kubectl delete -f  $TOP_LEVEL/argocd/argocd-applications/development/cdm-data-pipeline-abc.yaml