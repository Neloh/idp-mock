# Terraform — AgentCore Runtime Infrastructure

This is the IaC layer that provisions the actual AWS resources for the IDP.

## What It Creates

```
VPC (10.0.0.0/16)
├── Public Subnets (2x) — NAT Gateway lives here
├── Private Subnets (2x) — AgentCore Runtime ENIs live here
├── Internet Gateway — outbound for NAT
├── NAT Gateway — gives private subnets internet access
├── Security Group — HTTPS egress only (least privilege)
├── VPC Endpoints — ECR, CloudWatch Logs, S3 (avoids NAT charges)
├── IAM Role — for AgentCore to invoke Bedrock models
├── CloudWatch Log Group — runtime logs (90 day retention)
└── AgentCore Runtime — deployed with VPC mode into private subnets
```

## How It Fits in the IDP

```
Engineer submits spec
       |
       v
idp-mock validates + approves
       |
       v
Generates terraform.tfvars from spec
       |
       v
Opens PR → GitHub Actions runs `terraform plan`
       |
       v
Platform team reviews plan + approves PR
       |
       v
Merge → GitHub Actions runs `terraform apply`
       |
       v
Infrastructure created in AWS
```

## Prerequisites

1. AWS account with credentials configured
2. S3 bucket for Terraform state (run `./bootstrap.sh` once)
3. GitHub repository secret: `AWS_ROLE_ARN`

## Local Usage

```bash
# First time setup (creates state bucket + DynamoDB lock table)
./bootstrap.sh

# Plan
cd terraform
terraform init
terraform plan

# Apply (only after approval)
terraform apply
```

## Destroying

```bash
cd terraform
terraform destroy
```

This removes all resources: VPC, subnets, NAT, security group, endpoints, IAM role, AgentCore Runtime.
