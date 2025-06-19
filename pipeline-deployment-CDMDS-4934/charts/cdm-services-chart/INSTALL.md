## Helm chart structure
```t
See at the end of this documentation.
```

## Get the top-level directory of the Git repository
```sh
TOP_LEVEL=$(git rev-parse --show-toplevel)
export TOP_LEVEL
```

## Step-1: Provision EKS cluster
```t
    By infrastructure team
```

## Step-2: Provision a bastion host
```t
    By infrastructure team
    - install kubectl
    - install jq, yq, curl
```

## Step-3: install ESO (External Secrets Operator)
```sh
cd $TOP_LEVEL/charts
helm repo add external-secrets https://charts.external-secrets.io
helm repo update
helm upgrade --install external-secrets external-secrets/external-secrets -n external-secrets --create-namespace --version 0.15.0

## Remove
helm uninstall external-secrets -n external-secrets 
```

## Step-4: install stakater/reloader
```sh
cd $TOP_LEVEL/charts
helm repo add stakater https://stakater.github.io/stakater-charts
helm repo update
helm upgrade --install reloader stakater/reloader --namespace reloader --create-namespace

## Remove
helm uninstall reloader -n reloader
```

## Step-5: create namespaces
```sh
cd $TOP_LEVEL/charts
kubectl create ns pre-install
helm upgrade --install pre-install pre-install-chart -n pre-install -f pre-install-chart/development.yaml

## Remove the chart
helm uninstall pre-install -n pre-install
```

## Step-6: create IRSA (IAM Roles for Service Accounts)
```sh

## Create an IAM Roles for Service Account (IRSA)
cd $TOP_LEVEL/role-policy

aws iam create-role \
    --role-name abc-cdm-role \
    --assume-role-policy-document file://abc-cdm-trust-relationships.json

aws iam create-role \
    --role-name xyz-cdm-role \
    --assume-role-policy-document file://xyz-cdm-trust-relationships.json

aws iam create-role \
    --role-name cdm-eso-role \
    --assume-role-policy-document file://cdm-eso-trust-relationships.json

aws iam create-role \
    --role-name cdm-dictionary-connector-role \
    --assume-role-policy-document file://cdm-dictionary-connector-trust-relationships.json

## Create an IAM policies
cd $TOP_LEVEL/role-policy

aws iam create-policy \
    --policy-name abc-cdm-policy \
    --policy-document file://abc-cdm-policy.json

aws iam create-policy \
    --policy-name xyz-cdm-policy \
    --policy-document file://xyz-cdm-policy.json

aws iam create-policy \
    --policy-name cdm-eso-policy \
    --policy-document file://cdm-eso-policy.json

aws iam create-policy \
    --policy-name cdm-dictionary-connector-policy \
    --policy-document file://cdm-dictionary-connector-policy.json

## Attach the Policies to Roles
cd $TOP_LEVEL/role-policy

aws iam attach-role-policy \
    --role-name abc-cdm-role \
    --policy-arn arn:aws-us-gov:iam::283857190015:policy/abc-cdm-policy

aws iam attach-role-policy \
    --role-name xyz-cdm-role \
    --policy-arn arn:aws-us-gov:iam::283857190015:policy/xyz-cdm-policy

aws iam attach-role-policy \
    --role-name cdm-eso-role \
    --policy-arn arn:aws-us-gov:iam::283857190015:policy/cdm-eso-policy

aws iam attach-role-policy \
    --role-name cdm-dictionary-connector-role \
    --policy-arn arn:aws-us-gov:iam::283857190015:policy/cdm-dictionary-connector-policy
```

## Step-7: create clustersecretstore
```sh
kubectl apply -f  $TOP_LEVEL/external-secrets/cluster-secret-store-local-development.yaml

## Check if ClusterSecretStore was created
kubectl get ClusterSecretStore -A
```

## Step-8: create image pull secrets for ECR and verify
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


## Step-9: install cdm-services-chart Helm chart
```sh
# Run the following command to install the chart:
cd charts
helm upgrade --install cdm-services-chart cdm-services-chart/ -n cdm-services-chart-ns -f cdm-services-chart/dev-values.yaml --create-namespace
OR
helm upgrade --install cdm-services-chart cdm-services-chart/ -n cdm-services-chart-ns -f cdm-services-chart/prod-values.yaml --create-namespace
```

## Step-10: uninstall cdm-services-chart Helm chart 
```sh
# Run the following command to install the chart:
helm uninstall cdm-services-chart -n cdm-services-chart-ns
```

## Important Note on Dictionary Connector
The dictionary-connector uses a cron job to schedule daily runs at 12AM EST which pulls updated seed files from the `pipeline-seed-files` bucket in S3. If the pod needs to be run separately from the daily run, it can be executed with this command:
`kubectl apply -f dictionary-connector.yaml --namespace dictionary-connector`

## Below is the Helm chart structure
```sh
cdm-services-chart/
├── Chart.yaml             # Helm chart metadata
├── values.yaml            # Default values for the chart
├── dev-values.yaml        # Values specific to the development environment
├── prod-values.yaml       # Values specific to the production environment
├── _helpers.tpl           # Template helper functions (e.g., labels, names)
├── .helmignore            # Files to ignore when packaging the chart
├── NOTES.txt              # Post-installation instructions for the user
├── README.md              # Documentation for the Helm chart
├── charts/                # Directory for Helm chart dependencies
├── templates/             # Stores Kubernetes resource templates
│   ├── abc-cdm-data-pipeline/
│   │   ├── abc-armis-connector/
│   │   │   ├── deployment.yaml
│   │   │   ├── configmap.yaml
│   │   │   ├── externalsecret.yaml
│   │   ├── abc-armis-processor/
│   │   │   ├── deployment.yaml
│   │   │   ├── configmap.yaml
│   │   │   ├── externalsecret.yaml     
│   │   ├── abc-cdm-processor/
│   │   │   ├── serviceaccount.yaml
│   │   │   ├── deployment.yaml
│   │   │   ├── configmap.yaml
│   │   │   ├── externalsecret.yaml      
│   │   ├── abc-elastic-sink/
│   │   │   ├── deployment.yaml
│   │   │   ├── configmap.yaml
│   │   │   ├── externalsecret.yaml      
│   │   ├── abc-quality-cdm-processor/
│   │   │   ├── serviceaccount.yaml
│   │   │   ├── deployment.yaml
│   │   │   ├── configmap.yaml
│   │   │   ├── externalsecret.yaml       
│   │   ├── abc-quality-elastic-sink/
│   │   │   ├── deployment.yaml
│   │   │   ├── configmap.yaml
│   │   │   ├── externalsecret.yaml       
│   │
│   ├── xyz-cdm-data-pipeline/
│   │   ├── xyz-axonius-connector/
│   │   │   ├── deployment.yaml
│   │   │   ├── configmap.yaml
│   │   │   ├── externalsecret.yaml      
│   │   ├── xyz-axonius-processor/
│   │   │   ├── deployment.yaml
│   │   │   ├── configmap.yaml
│   │   │   ├── externalsecret.yaml      
│   │   ├── xyz-cdm-processor/
│   │   │   ├── serviceaccount.yaml
│   │   │   ├── deployment.yaml
│   │   │   ├── configmap.yaml
│   │   │   ├── externalsecret.yaml      
│   │   ├── xyz-elastic-sink/
│   │   │   ├── deployment.yaml
│   │   │   ├── configmap.yaml
│   │   │   ├── externalsecret.yaml       
│   │   ├── xyz-quality-cdm-processor/
│   │   │   ├── serviceaccount.yaml
│   │   │   ├── deployment.yaml
│   │   │   ├── configmap.yaml
│   │   │   ├── externalsecret.yaml      
│   │   ├── xyz-quality-elastic-sink/
│   │   │   ├── deployment.yaml
│   │   │   ├── configmap.yaml
│   │   │   ├── externalsecret.yaml  
│   │
│   ├── cdm-dictionary-connector/
│   │   ├── serviceaccount.yaml
│   │   ├── configmap.yaml
│   │   ├── cronjob.yaml

```
