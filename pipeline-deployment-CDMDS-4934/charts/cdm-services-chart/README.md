## Run the following command to install the chart:
```sh
cd k8s-operator-pocs
helm upgrade --install cdm-chart cdm-services-chart/ -n cdm-services-chart -f charts/dev-values.yaml --create-namespace
OR
helm upgrade --install cdm-chart ccdm-services-chart/ -n cdm-services-chart -f charts/prod-values.yaml --create-namespace
```

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