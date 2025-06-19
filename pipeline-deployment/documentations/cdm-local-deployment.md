## Minikube
```sh
## Start Minikube 
minikube start --cpus=6 --memory=10g --disk-size=50g --driver=docker

## Delete Minikube
minikube delete

## Stop Minikube
minikube stop
```

## Set top Level
```sh
TOP_LEVEL=$(git rev-parse --show-toplevel)
```

## Create Namespaces
```sh
cd $TOP_LEVEL/charts
kubectl create ns pre-install
helm upgrade --install pre-install pre-install-chart -n pre-install -f pre-install-chart/development.yaml

## Remove the chart
helm uninstall pre-install -n pre-install
```

## Install External Secrets Operator (ESO)
```sh
cd $TOP_LEVEL/charts
helm upgrade --install external-secrets external-secrets -n external-secrets -f external-secrets/values.yaml

## Remove
helm uninstall external-secrets -n pre-install 
```

## Install Reloader
```sh
cd $TOP_LEVEL/charts
helm upgrade --install reloader reloader -n reloader -f reloader/values.yaml

## Remove
helm uninstall reloader -n reloader
```

## Set AWS Credentials as Kubernetes Secret
```sh
#!/bin/bash

# Set your AWS credentials
export AWS_ACCESS_KEY_ID="XXXXXXXXXXXXXXXXXXXXXXXX"
export AWS_SECRET_ACCESS_KEY="XXXXXXXXXXXXXXXXXXXX"
export AWS_REGION="us-gov-east-1"

# Namespaces that require aws-credentials secret
NAMESPACES=(
  external-secrets
  xyz-cdm-processor
  xyz-quality-cdm-processor
  abc-cdm-processor
  abc-quality-cdm-processor
  cdm-dictionary-connector
)

for ns in "${NAMESPACES[@]}"; do
  echo "Creating aws-credentials secret in namespace: $ns"
  kubectl create secret generic aws-credentials \
    --namespace "$ns" \
    --from-literal=AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
    --from-literal=AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
    --from-literal=AWS_REGION="${AWS_REGION}"
done

## Verify that the secret was created:
for ns in \
  external-secrets \
  xyz-cdm-processor \
  xyz-quality-cdm-processor \
  abc-cdm-processor \
  abc-quality-cdm-processor \
  cdm-dictionary-connector
do
  kubectl get secret aws-credentials -n $ns
done
```

## Create Kubernetes pull secrets for ECR
```sh
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
```

## Create ESO ClusterSecretStore
```sh
kubectl apply -f  $TOP_LEVEL/external-secrets/cluster-secret-store-local-development.yaml

## Check if ClusterSecretStore was created
kubectl get ClusterSecretStore -A
```

## Create ExternalSecrets for cdm-data-pipeline-abc-pipeline-core
```sh
cd external-secrets
kubectl apply -f cdm-data-pipeline-abc-pipeline-core

## Check if ExternalSecrets were  created
kubectl get ExternalSecret -A
```

## Apply ClusterSecretStore and ExternalSecrets
```sh
kubectl apply -f  $TOP_LEVEL/external-secrets/cluster-secret-store-local-development.yaml
kubectl apply -f  $TOP_LEVEL/external-secrets/cdm-cfk-secrets
kubectl apply -f  $TOP_LEVEL/external-secrets/cdm-data-pipeline-abc-pipeline-core
kubectl apply -f  $TOP_LEVEL/external-secrets/cdm-data-pipeline-xyz-pipeline-core

## Check if ExternalSecrets were  created
kubectl get ExternalSecret -A

## Check if ClusterSecretStore was created
kubectl get ClusterSecretStore -A
```

## Deploy confluent operator
```sh
cd $TOP_LEVEL/charts
helm upgrade --install confluent-operator \
  confluentinc/confluent-for-kubernetes \
  --set kRaftEnabled=true \
  --set fipsmode=true \
  --namespace cdm-kafka

## Removed confluent-operator
helm uninstall confluent-operator -n cdm-kafka  
```

## Deploy ldap
```sh
cd $TOP_LEVEL/charts
helm upgrade --install \
  -f openldap/ldaps-rbac.yaml \
  cdm-ldap openldap \
  --namespace cdm-kafka

## Removed confluent-operator
helm uninstall openldap -n cdm-kafka  
```

## Deploy CFK
```sh
kubectl apply -f $TOP_LEVEL/cdm-cfk/local-deployment
```

## Deploy Pipeline Core Components
```sh
kubectl apply -f $TOP_LEVEL/cdm-data-pipeline-pipeline-core/local-deployment/cdm-data-pipeline-xyz-pipeline-core
kubectl apply -f $TOP_LEVEL/cdm-data-pipeline-pipeline-core/local-deployment/cdm-data-pipeline-abc-pipeline-core
# kubectl apply -f $TOP_LEVEL/cdm-data-pipeline-pipeline-core/local-deployment/cdm-dictionary-connector.yaml
```
