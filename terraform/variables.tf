variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "idp-agentcore"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (min 2 for HA)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (for NAT gateway)"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "agent_runtime_name" {
  description = "Name of the AgentCore runtime"
  type        = string
  default     = "idp-platform-runtime"
}

variable "foundation_model" {
  description = "Bedrock model inference profile ID"
  type        = string
  default     = "us.anthropic.claude-sonnet-4-6"
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
  default     = "<YOUR_ACCOUNT_ID>"
}
