
# Deploy DevSecOps (DSO) component Helm chart(s)
## Run pre_install.sh
```sh

## Run the following commands:
cd $(git rev-parse --show-toplevel)
bash ./scripts/pre_install.sh

## For local testing only:
cd $(git rev-parse --show-toplevel)
bash ./scripts/pre_install.sh --local --aws-access-key-id "aws-key-id"  --aws-secret-access-key "aws-secret-key"

## For help run:
cd $(git rev-parse --show-toplevel)
bash ./scripts/pre_install.sh --help

```

