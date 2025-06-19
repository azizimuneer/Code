#!/bin/bash

set -e 

# Function to help user
show_help() {
  echo "Usage: $0 [--local | --eks | --help]"
  echo ""
  echo "Options:"
  echo "  --local, -l Run the script locally. Prompts for AWS credentials."
  echo "              --aws-access-key-id Provide AWS Access Key ID. Required for local deployment."
  echo "              --aws-secret-access-key Provide AWS Secret Key. Required for local deployment."
  echo "  --eks, -e Run the script on a AWS host. Uses instance metadata to get AWS account ID."
  echo "  --help, -h Show options."
}

# Set Defaults
MODE="eks"
AWS_ACCESS_KEY_ID=""
AWS_SECRET_ACCESS_KEY=""

# Parse flags
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --local|-l) 
      MODE="local"
      ;;
    --eks|-e)
      MODE="eks"
      ;;
    --aws-access-key-id|-u)
      if [[ ! "$2" || "$2" == -* ]]; then
        echo "Error: --aws-access-key-id requires a value."
        exit 1
      fi
      AWS_ACCESS_KEY_ID="$2"
      shift
      ;;
    --aws-secret-access-key|-s)
      if [[ ! "$2" || "$2" == -* ]]; then
        echo "Error: --aws-secret-access-key requires a value."
        exit 1
      fi
      AWS_SECRET_ACCESS_KEY="$2"
      shift
      ;;
    --help | -h)
      show_help;
      exit 0
      ;;
    *)
      echo "Unknown option: $1";
      show_help;
      exit 1
      ;;
  esac
    shift
done

# Validate proper usage
if [[ "$MODE" != "local" ]]; then
  if [[ -n "$AWS_ACCESS_KEY_ID" || -n "$AWS_SECRET_ACCESS_KEY" ]]; then
    echo "Error: AWS Credentials should only be provided with --local mode."
    exit 1
  fi
fi

## Get the top-level directory of the Git repository
TOP_LEVEL=$(git rev-parse --show-toplevel)
export TOP_LEVEL
CHART_DIR="$TOP_LEVEL/charts"

# Set default AWS variables
AWS_REGION="us-gov-east-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

if [ "$MODE" == "local" ]; then
  if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    read -p "Enter your AWS Access Key ID: " AWS_ACCESS_KEY_ID
  fi
  if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    read -s -p "Enter your AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
    echo ""
  fi
  export AWS_ACCOUNT_ID AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION

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
  ## TODO CHANGE MEM BACK TO 10
  if is_minikube_running; then
    echo "Minikube is already running."
  else
    echo "Starting Minikube..."
    minikube start --cpus=6 --memory=6g --disk-size=50g --driver=docker
    wait_for_minikube
  fi
  
else
  export AWS_ACCOUNT_ID AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION
fi

# Install External Secrets Operator (ESO)
EXTERNAL_SECRETS_VERSION="0.15.0"

echo "Installing or upgrading Helm chart for External Secrets Operator (ESO)"
helm repo add external-secrets https://charts.external-secrets.io
helm repo update
helm upgrade --install external-secrets external-secrets/external-secrets --namespace external-secrets \
  --create-namespace \
  --version "$EXTERNAL_SECRETS_VERSION"

for deploy in $(kubectl get deploy -n external-secrets -o jsonpath='{.items[*].metadata.name}'); do
  echo "Waiting for deployment $deploy to be ready..."
  kubectl rollout status deployment/$deploy -n external-secrets --timeout=120s
done

# Install Reloader Operator
RELOADER_VERSION="2.1.2"

echo "Installing or upgrading Helm chart for Reloader Operator"
helm repo add stakater https://stakater.github.io/stakater-charts
helm repo update
helm upgrade --install reloader stakater/reloader --namespace reloader \
  --create-namespace \
  --version "$RELOADER_VERSION"

#Install Pre Install Chart
echo "Installing or upgrading Helm chart for Pre Install"
if [ "$MODE" == "local" ]; then

  helm upgrade --install -i pre-install "$CHART_DIR/pre-install-chart/" --namespace pre-install \
    --create-namespace \
    --set aws.env="local" \
    --set aws.accountId="$AWS_ACCOUNT_ID" \
    --set aws.region="$AWS_REGION" \

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

  else

  helm upgrade --install -i pre-install "$CHART_DIR/pre-install-chart/" --namespace pre-install \
    --create-namespace \
    --set aws.env="eks" \
    --set aws.accountId="$AWS_ACCOUNT_ID" \
    --set aws.region="$AWS_REGION"
fi