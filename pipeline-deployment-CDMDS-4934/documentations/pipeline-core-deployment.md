# PVS Deployment Script

## Overview

This script automates the process of:

- Verifying the existence of a given Docker image tag in **AWS ECR**
- Preparing Kubernetes deployment manifests for **PVS** or **NO-PVS** deployments
- Substituting the image tag (`IMAGE_TAG`) in all relevant YAML files
- Copying and organizing manifests into a dedicated deployment folder
- Dynamically selecting the appropriate **Kubernetes context**
- Applying manifests in a logical dependency order

## Prerequisites
- Bash (`bash`) installed
- `kubectl` installed and configured
- Access to a Kubernetes cluster
- Git repository properly cloned with the following structure:

## Script Parameters
| Parameter    | Description                                    | Example                |
|--------------|------------------------------------------------|------------------------|
| `IMAGE_TAG`  | The PVS image tag to deploy (example: pvs1.0.0) | `pvs1.0.0`             |
| `DEPLOY_TYPE`| Deployment type: `pvs` or `no-pvs`              | `pvs`, `no-pvs`        |

## Usage

```bash
bash pipeline-core-deployment.sh <IMAGE_TAG> <DEPLOY_TYPE>
```
Examples: 
- Deploy using PVS: `bash pipeline-core-deployment.sh pvs1.0.0 pvs`
- Deploy using NO-PVS: `bash pipeline-core-deployment.sh pvs1.0.0 no-pvs`

## Script Workflow

### 1. Parameter Validation
- Checks if both `IMAGE_TAG` and `DEPLOY_TYPE` parameters are provided.
- Shows usage help if arguments are missing.

### 2. Select Source and Target
- Selects either `eks-deployment` or `no-pvs-eks-deployment` as the source directory based on the deployment type.
- Creates a corresponding deployment directory:
  - `deployment-pvs/`
  - `deployment-no-pvs/`

### 3. Prepare Deployment Directory
- Cleans up any old deployment folders if they exist.
- Copies all relevant YAML files into the new deployment directory.
- Substitutes the `IMAGE_TAG` placeholder with the provided `IMAGE_TAG` value in all `.yaml` and `.yml` files.

### 4. Deploy Manifests
- Changes into the newly created deployment directory.
- Lists all prepared YAML files for review.
- Applies manifests to the Kubernetes cluster in a logical dependency order:
  - **Connectors**
  - **Processors**
  - **Sinks**
  - **Quality CDM Processors**
  - **Dictionary Connector**

## Deployment Order
Manifests are applied in the following logical order (example for `deployment-pvs/`):

### Connectors
- `deployment-pvs/abc-armis-connector.yaml`
- `deployment-pvs/xyz-axonius-connector.yaml`

### Processors
- `deployment-pvs/abc-armis-processor.yaml`
- `deployment-pvs/abc-cdm-processor.yaml`
- `deployment-pvs/xyz-axonius-processor.yaml`
- `deployment-pvs/xyz-cdm-processor.yaml`

### Sinks
- `deployment-pvs/abc-elastic-sink.yaml`
- `deployment-pvs/abc-quality-elastic-sink.yaml`
- `deployment-pvs/xyz-elastic-sink.yaml`
- `deployment-pvs/xyz-quality-elastic-sink.yaml`

### Quality CDM Processors
- `deployment-pvs/abc-quality-cdm-processor.yaml`
- `deployment-pvs/xyz-quality-cdm-processor.yaml`

### Dictionary Connector
- `deployment-pvs/cdm-dictionary-connector.yaml`