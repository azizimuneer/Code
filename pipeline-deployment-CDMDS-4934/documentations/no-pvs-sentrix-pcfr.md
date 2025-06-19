## Get the top-level directory of the Git repository
```sh
TOP_LEVEL=$(git rev-parse --show-toplevel)
export TOP_LEVEL
```

## Create AWS IAM Policy and attach this policy to an IAM role, associate it with the Kubernetes serviceAccount using IRSA (IAM Roles for Service Accounts) for directory connect.
```sh
## Create an IAM Roles for Service Account (IRSA)
cd $TOP_LEVEL/role-policy/no-pvs-sentrix-pcfr 

aws iam create-role \
    --role-name abc-cdm-no-pvs-role \
    --assume-role-policy-document file://abc-cdm-trust-relationships.json

aws iam create-role \
    --role-name xyz-cdm-no-pvs-role \
    --assume-role-policy-document file://xyz-cdm-trust-relationships.json

aws iam create-role \
    --role-name cdm-eso-no-pvs-role \
    --assume-role-policy-document file://cdm-eso-trust-relationships.json

aws iam create-role \
    --role-name cdm-dictionary-connector-no-pvs-role \
    --assume-role-policy-document file://cdm-dictionary-connector-trust-relationships.json

# ## Create an IAM policies
# cd $TOP_LEVEL/role-policy

# aws iam create-policy \
#     --policy-name abc-cdm-policy \
#     --policy-document file://abc-cdm-policy.json

# aws iam create-policy \
#     --policy-name xyz-cdm-policy \
#     --policy-document file://xyz-cdm-policy.json

# aws iam create-policy \
#     --policy-name cdm-eso-policy \
#     --policy-document file://cdm-eso-policy.json

# aws iam create-policy \
#     --policy-name cdm-dictionary-connector-policy \
#     --policy-document file://cdm-dictionary-connector-policy.json

## Attach the Policies to Roles
cd $TOP_LEVEL/role-policy

aws iam attach-role-policy \
    --role-name abc-cdm-no-pvs-role \
    --policy-arn arn:aws-us-gov:iam::ACCOUNTID:policy/abc-cdm-policy

aws iam attach-role-policy \
    --role-name xyz-cdm-no-pvs-role \
    --policy-arn arn:aws-us-gov:iam::ACCOUNTID:policy/xyz-cdm-policy

aws iam attach-role-policy \
    --role-name cdm-eso-no-pvs-role \
    --policy-arn arn:aws-us-gov:iam::ACCOUNTID:policy/cdm-eso-policy

aws iam attach-role-policy \
    --role-name cdm-dictionary-connector-no-pvs-role \
    --policy-arn arn:aws-us-gov:iam::ACCOUNTID:policy/cdm-dictionary-connector-policy
```

## Create namespces
```sh
for ns in \
  abc-armis-connector \
  abc-armis-processor \
  abc-cdm-processor \
  abc-quality-cdm-processor \
  abc-elastic-sink \
  abc-quality-elastic-sink \
  xyz-axonius-connector \
  xyz-axonius-processor \
  xyz-cdm-processor \
  xyz-quality-cdm-processor \
  xyz-elastic-sink \
  xyz-quality-elastic-sink \
  cdm-dictionary-connector \
  external-secrets \
  reloader
do
  kubectl create namespace $ns
done
```
## Create Kubernetes pull secrets for ECR
```sh
#!/bin/bash

AWS_ACCOUNT_ID=ACCOUNTID
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
  external-secrets
  reloader
)

for ns in "${NAMESPACES[@]}"; do
  echo "Creating image pull secret in namespace: $ns"
  kubectl create secret docker-registry ecr-secret \
    --docker-server=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com \
    --docker-username=AWS \
    --docker-password=$(aws ecr get-login-password --region $AWS_REGION) \
    --namespace $ns
done
```

## Create Kubernetes pull secrets for ECR
```sh
AWS_ACCOUNT_ID=ACCOUNTID
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
```

## Install External Secrets Operator (ESO)
```sh
cd $TOP_LEVEL/charts
helm upgrade --install external-secrets external-secrets -n external-secrets -f external-secrets/values.yaml
```

## Install Reloader
```sh
cd $TOP_LEVEL/charts
helm upgrade --install reloader reloader -n reloader -f reloader/values.yaml
```

## Create a ClusterSecretStore service account
```sh
cd $TOP_LEVEL/external-secrets
kubectl apply -f no-pvs-sa.yaml

## Check if service account was created
kubectl get sa -ns external-secrets
```

## Create a ClusterSecretStore
```sh
cd $TOP_LEVEL/external-secrets
kubectl apply -f cluster-secret-store.yaml

## Check if ClusterSecretStore was created
kubectl get ClusterSecretStore -A
```

## Create ExternalSecrets
```sh
cd $TOP_LEVEL/external-secrets 
kubectl apply -f cdm-data-pipeline-abc-pipeline-core
kubectl apply -f cdm-data-pipeline-xyz-pipeline-core
```

## Deployment pipelines components
```sh
cd $TOP_LEVEL/cdm-data-pipeline-pipeline-core/eks-deployment-no-pvc
kubectl apply -f cdm-data-pipeline-abc-pipeline-core
kubectl apply -f cdm-data-pipeline-xyz-pipeline-core
kubectl apply -f cdm-dictionary-connector.yaml
```