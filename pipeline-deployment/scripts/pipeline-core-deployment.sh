#!/bin/bash

# ---------------------
# Script Usage and Parameter Validation
# ---------------------
usage() {
  echo "Usage: $0 <IMAGE_TAG> <DEPLOY_TYPE>"
  echo
  echo "Arguments:"
  echo "  IMAGE_TAG     The PVS image tag to deploy (example: pvs1.0.0)"
  echo "  DEPLOY_TYPE   Deployment type: 'pvs' or 'no-pvs'"
  echo
  echo "Example:"
  echo "  $0 pvs1.0.0 pvs"
  echo "  $0 pvs1.0.0 no-pvs"
  exit 1
}

if [ $# -ne 2 ]; then
  echo "Error: Invalid number of arguments."
  usage
fi

IMAGE_TAG="$1"
DEPLOY_TYPE="$2"

DEPLOY_TYPE_LOWER=$(echo "$DEPLOY_TYPE" | tr '[:upper:]' '[:lower:]')

# ---------------------
# Verify IMAGE_TAG exists in ECR
# ---------------------
AWS_ACCOUNT_ID="ACCOUNTID"
AWS_REGION="us-gov-east-1"
REPOSITORY_NAME="pipeline/pipeline-core"

echo "Fetching available image tags from ECR repository: $REPOSITORY_NAME"
IMAGE_TAGS=$(aws ecr describe-images \
  --registry-id "$AWS_ACCOUNT_ID" \
  --repository-name "$REPOSITORY_NAME" \
  --region "$AWS_REGION" \
  --query 'imageDetails[].imageTags[]' \
  --output text)

if [ -z "$IMAGE_TAGS" ]; then
  echo "Error: No image tags found in ECR repository: $REPOSITORY_NAME"
  exit 1
fi

echo "Available image tags:"
echo "$IMAGE_TAGS" | tr '\t' '\n' | sort

if ! echo "$IMAGE_TAGS" | grep -wq "$IMAGE_TAG"; then
  echo "Error: Image tag '$IMAGE_TAG' not found in ECR repository: $REPOSITORY_NAME"
  exit 1
fi
echo "Image tag '$IMAGE_TAG' found in ECR. Continuing..."

# ---------------------
# Select Source Directory and Prepare Deployment Directory
# ---------------------
case $DEPLOY_TYPE_LOWER in
  pvs)
    echo "You chose to deploy PVS with image tag: $IMAGE_TAG"
    SOURCE_DIR=$(git rev-parse --show-toplevel)/cdm-data-pipeline-pipeline-core/eks-deployment
    DEPLOY_DIR_NAME="deployment-pvs"
    ;;
  no-pvs)
    echo "You chose to deploy NO-PVS with image tag: $IMAGE_TAG"
    SOURCE_DIR=$(git rev-parse --show-toplevel)/cdm-data-pipeline-pipeline-core/eks-deployment-no-pvs
    DEPLOY_DIR_NAME="deployment-no-pvs"
    ;;
  *)
    echo "Invalid deployment type: $DEPLOY_TYPE"
    exit 1
    ;;
esac

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: Directory not found: $SOURCE_DIR"
  exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
DEPLOY_DIR="$REPO_ROOT/$DEPLOY_DIR_NAME"

echo "Creating deployment directory: $DEPLOY_DIR"
rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR"

# ---------------------
# Substitute Image Tag In all yaml Files
# ---------------------
echo "Copying and updating YAML files..."
find "$SOURCE_DIR" -type f \( -iname "*.yaml" -o -iname "*.yml" \) | while read -r file; do
  REL_PATH="${file#$SOURCE_DIR/}"
  DEST_FILE="$DEPLOY_DIR/$REL_PATH"

  mkdir -p "$(dirname "$DEST_FILE")"
  sed "s|IMAGE_TAG|$IMAGE_TAG|g" "$file" > "$DEST_FILE"
done

echo "All files have been prepared in: $DEPLOY_DIR"

# ---------------------
# Change Directory to Deployment Folder and List Files
# ---------------------
cd "$DEPLOY_DIR" || exit 1
echo "Listing contents of $(pwd):"
find .

# ---------------------
# Validate and Switch Kubernetes Context
# ---------------------
AVAILABLE_CONTEXTS=$(kubectl config get-contexts -o name)

if [ "$DEPLOY_TYPE_LOWER" = "pvs" ]; then
    REQUIRED_CONTEXT=$(echo "$AVAILABLE_CONTEXTS" | grep -E "^arn:.*:cluster/sentrix-pcfr$")
elif [ "$DEPLOY_TYPE_LOWER" = "no-pvs" ]; then
    REQUIRED_CONTEXT=$(echo "$AVAILABLE_CONTEXTS" | grep -E "^arn:.*:cluster/no-pvs-sentrix-pcfr$")
else
    echo "Error: Invalid deployment type '$DEPLOY_TYPE_LOWER'."
    exit 1
fi

if [ -z "$REQUIRED_CONTEXT" ]; then
    echo "Error: Matching context not found for '$DEPLOY_TYPE_LOWER'"
    echo "Available contexts:"
    echo "$AVAILABLE_CONTEXTS"
    exit 1
fi

CURRENT_CONTEXT=$(kubectl config current-context)

if [ "$CURRENT_CONTEXT" != "$REQUIRED_CONTEXT" ]; then
    echo "Current context ($CURRENT_CONTEXT) does not match required context ($REQUIRED_CONTEXT)."
    echo "Switching context..."
    kubectl config use-context "$REQUIRED_CONTEXT"
else
    echo "Current context ($CURRENT_CONTEXT) is already correct."
fi

# ---------------------
# Apply Kubernetes Manifests in Logical Order
# ---------------------
echo "Applying manifests in logical order..."

# --- Connectors ---
kubectl apply -f cdm-data-pipeline-abc-pipeline-core/abc-armis-connector.yaml
kubectl apply -f cdm-data-pipeline-xyz-pipeline-core/xyz-axonius-connector.yaml

# --- Processors ---
kubectl apply -f cdm-data-pipeline-abc-pipeline-core/abc-armis-processor.yaml
kubectl apply -f cdm-data-pipeline-abc-pipeline-core/abc-cdm-processor.yaml
kubectl apply -f cdm-data-pipeline-xyz-pipeline-core/xyz-axonius-processor.yaml
kubectl apply -f cdm-data-pipeline-xyz-pipeline-core/xyz-cdm-processor.yaml

# --- Sinks ---
kubectl apply -f cdm-data-pipeline-abc-pipeline-core/abc-elastic-sink.yaml
kubectl apply -f cdm-data-pipeline-abc-pipeline-core/abc-quality-elastic-sink.yaml
kubectl apply -f cdm-data-pipeline-xyz-pipeline-core/xyz-elastic-sink.yaml
kubectl apply -f cdm-data-pipeline-xyz-pipeline-core/xyz-quality-elastic-sink.yaml

# --- Quality CDM Processors ---
kubectl apply -f cdm-data-pipeline-abc-pipeline-core/abc-quality-cdm-processor.yaml
kubectl apply -f cdm-data-pipeline-xyz-pipeline-core/xyz-quality-cdm-processor.yaml

# --- Dictionary Connector ---
kubectl apply -f cdm-dictionary-connector.yaml

echo "Deployment complete."
