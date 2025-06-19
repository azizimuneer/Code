
# Create the Package
helm package ./cluster-baseline 

## Show Schemas and ConfigMap
kubectl get schema
kubectl get configmap

#### Show the output template
helm template schema-deployment schemas-baseline-0.1.1.tgz

#### Dry Run
helm template schema-deployment schemas-baseline-0.1.1.tgz | kubectl apply -f - --dry-run=client

#### Deployment Execution
helm template schema-deployment schemas-baseline-0.1.1.tgz | kubectl apply -f -

#### List ConfigMap
kubectl get configmaps

#### Describe ConfigMap
kubectl describe configmap <configMapName>

#### List Schema
kubectl get schemas

#### Describe Schema
kubectl describe schema <schemaName>

### Getting logs by timestamp
```
kubectl logs kafka-0 -n confluent --since-time=2025-02-21T01:44:20Z > topics.log
``` 



```yaml
kubectl logs <pod_name> --since-time=2022-04-30T10:00:00Z | awk '$0 < "2022-04-30T11:00:00Z"'
```

```yaml
kubectl logs <pod_name> | awk '$0 > "2022-04-30 10:00:00"' | awk '$0 < "2022-04-30 11:00:00"'
```
