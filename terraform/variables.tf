variable "region" {
  default = "us-east-1"
}

variable "vpc_id" {
  description = "Existing VPC ID to deploy into"
  default     = "<YOUR_VPC_ID>"
}

variable "subnet_ids" {
  description = "Existing subnets in supported AZs"
  type        = list(string)
  default     = ["<SUBNET_1>", "<SUBNET_2>"]
}

variable "agent_runtime_name" {
  default = "idpRuntime"
}
