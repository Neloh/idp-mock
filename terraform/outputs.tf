output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs (where AgentCore Runtime ENIs live)"
  value       = aws_subnet.private[*].id
}

output "security_group_id" {
  description = "Security group for AgentCore Runtime"
  value       = aws_security_group.agentcore.id
}

output "nat_gateway_ip" {
  description = "NAT Gateway public IP (outbound internet for private subnets)"
  value       = aws_eip.nat.public_ip
}

output "iam_role_arn" {
  description = "IAM role ARN for AgentCore Runtime"
  value       = aws_iam_role.agentcore_runtime.arn
}

output "log_group" {
  description = "CloudWatch log group for AgentCore"
  value       = aws_cloudwatch_log_group.agentcore.name
}

output "agentcore_runtime_name" {
  description = "AgentCore Runtime name"
  value       = var.agent_runtime_name
}
