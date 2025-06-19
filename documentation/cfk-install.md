# Purpose
Install instructions for Confluent for Kubernetes (CFK). CFK is a cloud-native management control plane for deploying and managing Confluent in Kubernetes. It provides an interface to customize, deploy, and manage Confluent Platform through declarative API. CFK is deployment is managed by Helm, but all the various Confluent components have custom resource definitions (CRDs) that can be managed just like any other Kubernetes resource.

## Kubernetes Version
NOTE: Kubernetes Version 1.31 or later is required for CFK

```sh
kubectl version
```
```sh
#Sample kubectl version return
Client Version: v1.31.0
Kustomize Version: v5.5.0
Server Version: v1.31.0
```

## Prepare Environment

```sh
cd /home/ec2-user/code/betsie-kafka-k8
export BASE_DIR="$(pwd)"
export NAMESPACE="cdm-kafka"
export LICENSE_FILE="$BASE_DIR/cert/trial_license.txt"
```
```sh
# NOTE: k3s local testing environment needs additional step:
# export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```
```sh
# Option 1:
source env.sh
```

## Create Namespace

```sh
kubectl create namespace ${NAMESPACE}
kubectl config set-context --current --namespace=${NAMESPACE}
```
```sh
kubectl get pods
#Sound see
No resources found in cdm-kafka namespace.
```

## Load External-Secrets
```sh
# Look in README_secrets.txt for more details
# Demo code:
python3 $BASE_DIR/bin/update_secrets.py

# Apply mappings
kubectl apply -f $BASE_DIR/crd/cp-external-secerts.yaml

# List secrets
kubectl get secrets
```

## Deploy Lightweight Directory Access Protocol (LDAP)
```sh
helm upgrade --install \
  -f $BASE_DIR/openldap/ldaps-rbac.yaml \
  cdm-ldap $BASE_DIR/openldap \
  --namespace ${NAMESPACE}

# Wait until ldap-0 is stable and running
kubectl get pods
```
```sh
#Example return of kubectl get pods:
NAME                                  READY   STATUS   RESTARTS   AGE
ldap-0                                1/1     Running   0         60s
```

### Test LDAP 
```sh
kubectl --namespace ${NAMESPACE} exec -it ldap-0 -- bash
ldapsearch -LLL -x -H ldap://ldap.cdm-kafka.svc.cluster.local:389 -b  'dc=cdm,dc=gov' -D "cn=mds,dc=cdm,dc=gov" -w 'Developer!'
exit
```

## Deploy Confluent Operator (Namespaced Scope)

```sh
helm repo add confluentinc https://packages.confluent.io/helm
helm repo update
helm upgrade --install confluent-operator confluentinc/confluent-for-kubernetes \
        --set namespaced=false \
        --set kRaftEnabled=true \
        --set fipsmode=true \
        --set licenseKey="$(cat $LICENSE_FILE )"
```

## Check Pods
```sh
kubectl get pods
```

```sh
#Example return of kubectl get pods:
NAME                                  READY   STATUS    RESTARTS      AGE
confluent-operator-649bcfdf9b-d7lmp   1/1     Running   0             31s
ldap-0                                1/1     Running   1             87s
```
## Check License Secret
 NOTE: Secert must contain value in format license=<license_value>
```sh
kubectl get secrets confluent-operator-licensing -o json | jq '{name: .metadata.name,data: .data|map_values(@base64d)}'
```

```sh
#Example return of kubectl get secrets confluent-operator-licensing:
{
  "name": "confluent-operator-licensing",
  "data": {
    "license.txt": "license=eyJ0eXAiOiJKV1Q...."
  }
}
```

## Check and Monitor Operator Logs:
```sh
# NOTE: Most deployment errors will show up in these logs
CON_OP_NAME="$(kubectl get pods | grep confluent-operator | awk '{print $1}')"
kubectl logs $CON_OP_NAME
```

## Deploy CP Components

```sh
kubectl apply -f $BASE_DIR/rbac/kafka_service_account-0.yaml 
kubectl apply -f $BASE_DIR/crd/cp-components-core.yaml --namespace ${NAMESPACE} 
```

```sh
# Wait until Kafka is stable, about 3 minutes or so
watch -n1 kubectl get pods -n cdm-kafka
```
```sh
kubectl apply -f $BASE_DIR/crd/cp-components-schemaregistry.yaml --namespace ${NAMESPACE}
kubectl apply -f $BASE_DIR/rbac/cfrb-schemaregistry-0.yaml
kubectl apply -f $BASE_DIR/rbac/cfrb-schemaregistry-1.yaml
kubectl apply -f $BASE_DIR/rbac/cfrb-schemaregistry-2.yaml
```
```sh
kubectl --namespace ${NAMESPACE} exec -it ldap-0 -- bash
ldappasswd -H ldap://ldap.cdm-kafka.svc.cluster.local:389 -x -D "cn=admin,dc=cdm,dc=gov" -W -S "cn=sr,dc=cdm,dc=gov"
# new password is sr-secret  and LDAP password is confluentrox
exit
```
```sh
helm template topics-deployment $BASE_DIR/topics/topics-baseline-0.1.1.tgz | kubectl apply -f -
helm template schema-deployment $BASE_DIR/schemas/schemas-baseline-0.1.1.tgz | kubectl apply -f -
```

## Check logs:

```sh        
kubectl logs kraftcontroller-0
kubectl logs kafka-0
kubectl logs schemaregistry-0
```

## Test Kafka
Looks in test for various test clients

## Set Up Port-Forwarding
```sh
kubectl port-forward c3-0 9021:9021
```

## Tear Down

```sh
# Note: The tear down goes smoother when done in this /exact/ order
kubectl delete -f $BASE_DIR/crd/cp-components-schemaregistry.yaml
kubectl delete -f $BASE_DIR/crd/cp-components-core.yaml
helm delete confluent-operator
helm delete cdm-ldap
kubectl delete namespace cdm-kafka
```
### Final tear down:

```sh
kubectl patch crd/confluentrolebindings.platform.confluent.io -p '{"metadata":{"finalizers":[]}}' --type=merge
kubectl patch ns ${NAMESPACE} -p '{"metadata":{"finalizers":null}}'
kubectl delete clusterrole        confluent-operator
kubectl delete clusterrolebinding confluent-operator
```
