#!/bin/bash
# bootstrap.sh — One-time setup for Terraform remote state
# Creates S3 bucket + DynamoDB lock table

set -euo pipefail

REGION="us-east-1"
ACCOUNT_ID="<YOUR_ACCOUNT_ID>"
BUCKET="idp-terraform-state-${ACCOUNT_ID}"
TABLE="terraform-locks"

echo "[Bootstrap] Creating S3 state bucket: $BUCKET"
aws s3api create-bucket \
  --bucket "$BUCKET" \
  --region "$REGION" 2>/dev/null || echo "  Bucket already exists"

aws s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket "$BUCKET" \
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
  }'

aws s3api put-public-access-block \
  --bucket "$BUCKET" \
  --public-access-block-configuration '{
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
  }'

echo "[Bootstrap] Creating DynamoDB lock table: $TABLE"
aws dynamodb create-table \
  --table-name "$TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION" 2>/dev/null || echo "  Table already exists"

echo "[Bootstrap] Done. Terraform backend is ready."
echo "  Bucket: $BUCKET"
echo "  Table:  $TABLE"
echo "  Region: $REGION"
