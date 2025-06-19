#!/bin/bash

set -e 

## Get the top-level directory of the Git repository
TOP_LEVEL=$(git rev-parse --show-toplevel)
export TOP_LEVEL

## Prompt user for AWS Credentials
read -p "Enter your AWS Access Key ID: " AWS_ACCESS_KEY_ID
read -s -p "Enter your AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
echo ""
export AWS_REGION="us-gov-east-1"
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

## Create Namespaces and deploy pre-install dependencies
echo "Creating pre-install namespace and deploying Helm charts..."
cd $TOP_LEVEL/charts
kubectl get ns pre-install || kubectl create ns pre-install
helm upgrade --install pre-install pre-install-chart -n pre-install -f pre-install-chart/development.yaml

## Install External Secrets Operator (ESO)
echo "Installing External Secrets Operator..."
cd $TOP_LEVEL/charts
helm upgrade --install external-secrets external-secrets -n external-secrets -f external-secrets/values.yaml

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

## Install Reloader
echo "Installing Reloader..."
cd $TOP_LEVEL/charts
helm upgrade --install reloader reloader -n reloader -f reloader/values.yaml

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

## Apply ClusterSecretStore and ExternalSecrets
kubectl apply -f  $TOP_LEVEL/external-secrets/cluster-secret-store-local-development.yaml
kubectl apply -f  $TOP_LEVEL/external-secrets/cdm-cfk-secrets
kubectl apply -f  $TOP_LEVEL/external-secrets/cdm-data-pipeline-abc-pipeline-core
kubectl apply -f  $TOP_LEVEL/external-secrets/cdm-data-pipeline-xyz-pipeline-core

sleep 10
## Check if ExternalSecrets were  created
kubectl get ExternalSecret -A

## Check if ClusterSecretStore was created
kubectl get ClusterSecretStore -A

## Create Kubernetes pull secrets for ECR
AWS_ACCOUNT_ID=283857190015
AWS_REGION=us-gov-east-1

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

for ns in "${NAMESPACES[@]}"; do
  echo "Creating image pull secret in namespace: $ns"
  kubectl create secret docker-registry ecr-secret \
    --docker-server=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com \
    --docker-username=AWS \
    --docker-password=$(aws ecr get-login-password --region $AWS_REGION) \
    --namespace $ns
done

## Verify that the secret was created:
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
for ns in "${NAMESPACES[@]}"; do
  kubectl get secret ecr-secret -n "$ns" 
done

## Deploy Confluent Operator
cd $TOP_LEVEL/charts
helm upgrade --install confluent-operator \
  confluentinc/confluent-for-kubernetes \
  --set kRaftEnabled=true \
  --set fipsmode=true \
  --namespace cdm-kafka

## Deploy LDAP
cd $TOP_LEVEL/charts
helm upgrade --install \
  -f openldap/ldaps-rbac.yaml \
  cdm-ldap openldap \
  --namespace cdm-kafka

## Deploy Confluent Kafka Components (CFK)
kubectl apply -f $TOP_LEVEL/cdm-cfk/local-deployment
sleep 600

## Deploy Pipeline Core Components
kubectl apply -f $TOP_LEVEL/cdm-data-pipeline-pipeline-core/local-deployment/cdm-data-pipeline-xyz-pipeline-core
# kubectl apply -f $TOP_LEVEL/cdm-data-pipeline-pipeline-core/local-deployment/cdm-data-pipeline-abc-pipeline-core
# kubectl apply -f $TOP_LEVEL/cdm-data-pipeline-pipeline-core/local-deployment/cdm-dictionary-connector.yaml