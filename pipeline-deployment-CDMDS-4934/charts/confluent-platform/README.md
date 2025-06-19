## Helm chart structure
```t
confluent-platform/
├── Chart.yaml
├── values.yaml
├── dev-values.yaml
├── README.md
├── .helmignore
└── templates/
    ├── kraftcontroller.yaml
    ├── kafka.yaml
    ├── kafkarestclass.yaml
    └── schemaregistry.yaml
```

## Confluent Platform Helm Chart
```t
This Helm chart deploys Confluent Platform components using CRDs:
- KRaftController
- Kafka
- KafkaRestClass
- SchemaRegistry
```

## Usage

To install with default values:

```bash
cd charts
helm upgrade --install kafka-platform confluent-platform/ -n charts-ns --create-namespace
```

To install with dev values:

```bash
cd charts
helm upgrade --install kafka-platform confluent-platform/ -f confluent-platform/dev-values.yaml -n charts-ns --create-namespace
```

## Structure
- `values.yaml`: Default configuration
- `dev-values.yaml`: Development overrides
- `templates/`: Rendered Kubernetes CRDs
