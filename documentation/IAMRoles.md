# IAM Policy and Trust Relationship Hardening for CDM Processor and Dictionary Connector

## Overview

This documents the security hardening updates made to the IAM policies and trust relationships for the **CDM Processor** and **Dictionary Connector** components. The goal was to tighten permissions, eliminate unnecessary access, and improve the overall security posture of these components running in AWS GovCloud.

---

##  Prior State

The initial IAM configurations had the following security concerns:

- **Overly permissive permissions**: Wildcard actions (e.g., `elasticache:*`) and resources (`*`) were allowed.
- **Unnecessary access**: S3 permissions for `pipeline-seed-files` were included in the CDM processor policy without actual usage.
- **Broad trust relationships**: Wildcard namespaces were used in trust relationships, allowing unintended service accounts to assume roles.

### Example IAM Policy (Before)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "elasticache:*",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws-us-gov:s3:::pipeline-seed-files",
        "arn:aws-us-gov:s3:::pipeline-seed-files/*"
      ]
    }
  ]
}
```
### Example Trust Policy (Before)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws-us-gov:iam::EXAMPLEID:oidc-provider/oidc.eks.us-gov-east-1.amazonaws.com/id/EXAMPLEID"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.us-gov-east-1.amazonaws.com/id/EXAMPLEID:aud": "sts.amazonaws.com",
          "oidc.eks.us-gov-east-1.amazonaws.com/id/EXAMPLEID:sub": "system:serviceaccount:*:abc-cdm-sa"
        }
      }
    }
  ]
}
```
##  Updated State

Improvements were made to adhere to the principle of least privilege:

- **Scoped permissions**: Only necessary Elasticache actions are allowed (DescribeServerlessCaches, Connect).
- **Removed unused permissions**:  All S3 actions were removed from the CDM processor role.
- **Tighter trust boundaries**: Trust relationships are restricted to specific namespaces and service accounts.

### Updated IAM Policy
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "elasticache:DescribeServerlessCaches"
      ],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "elasticache:Connect"
      ],
      "Resource": [
        "arn:aws-us-gov:elasticache:us-gov-east-1:EXAMPLEID:serverlesscache:testcvecache"
      ]
    }
  ]
}
```

### Updated Trust Relationship
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws-us-gov:iam::EXAMPLEID:oidc-provider/oidc.eks.us-gov-east-1.amazonaws.com/id/EXAMPLEID"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.us-gov-east-1.amazonaws.com/id/EXAMPLEID:aud": "sts.amazonaws.com",
          "oidc.eks.us-gov-east-1.amazonaws.com/id/EXAMPLEID:sub": "system:serviceaccount:abc-cdm-processor:abc-cdm-sa"
        }
      }
    }
  ]
}
```


