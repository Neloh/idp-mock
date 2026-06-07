terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# ─── Security Group (only new resource in the VPC) ───
resource "aws_security_group" "agentcore" {
  name        = "${var.agent_runtime_name}-sg"
  description = "AgentCore Runtime - HTTPS egress only"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS outbound"
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS"
  }

  tags = {
    Name = "${var.agent_runtime_name}-sg"
  }
}

# ─── AgentCore Runtime ───
resource "null_resource" "agentcore_runtime" {
  depends_on = [aws_security_group.agentcore]

  triggers = {
    name            = var.agent_runtime_name
    subnets         = join(",", var.subnet_ids)
    security_groups = aws_security_group.agentcore.id
  }

  provisioner "local-exec" {
    command = <<-EOT
      EXISTING=$(aws bedrock-agentcore-control list-agent-runtimes \
        --region ${var.region} \
        --query "agentRuntimes[?agentRuntimeName=='${var.agent_runtime_name}'].agentRuntimeId" \
        --output text 2>/dev/null || echo "")

      if [ -n "$EXISTING" ] && [ "$EXISTING" != "None" ]; then
        echo "[AgentCore] Runtime already exists: $EXISTING"
      else
        echo "[AgentCore] Creating runtime: ${var.agent_runtime_name}"
        aws bedrock-agentcore-control create-agent-runtime \
          --region ${var.region} \
          --agent-runtime-name "${var.agent_runtime_name}" \
          --network-configuration '{
            "networkMode": "VPC",
            "networkModeConfig": {
              "subnets": ${jsonencode(var.subnet_ids)},
              "securityGroups": ["${aws_security_group.agentcore.id}"]
            }
          }'
      fi
    EOT
  }
}

output "security_group_id" {
  value = aws_security_group.agentcore.id
}

output "vpc_id" {
  value = var.vpc_id
}

output "subnet_ids" {
  value = var.subnet_ids
}
