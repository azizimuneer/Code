
# Create the Package
helm package ./topics-baseline 

## Show topics
kubectl get kafkaTopics

#### Show the output template
helm template topic-deployment topics-baseline-0.1.1.tgz

#### Dry Run
helm template topic-deployment topics-baseline-0.1.1.tgz | kubectl apply -f - --dry-run=client

#### Deployment Execution
helm template schema-deployment topics-baseline-0.1.1.tgz | kubectl apply -f -

#### List Topics 
kubectl get tkafkaTopics

#### Describe Schema
kubectl describe tkafkaTopic <topicName>>

### Getting logs by timestamp
```
kubectl logs kafka-0 -n confluent --since-time=2025-02-21T01:44:20Z > topics.log
``` 



```yaml
kubectl logs pod_name --since-time=2022-04-30T10:00:00Z | awk '$0 < "2022-04-30T11:00:00Z"'
```

```yaml
kubectl logs pod_name | awk '$0 > "2022-04-30 10:00:00"' | awk '$0 < "2022-04-30 11:00:00"'
```

### Connect to Pod
kubectl exec <podName> -it --bash

### Describe topic
kafka-topics --bootstrap-server kafka.cdm-kafka.svc.cluster.local:9071 --describe --topic <topicName> -command-config <propertiesFile>


### cat /tmp/kafka_kafka_user.properties
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username=<user name> password=<password>;
sasl.mechanism=PLAIN
security.protocol=SASL_SSL
ssl.truststore.location=<truststore.jks path>
ssl.truststore.password=<store password>
