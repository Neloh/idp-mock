# ─── CloudWatch Log Group ───
resource "aws_cloudwatch_log_group" "agentcore" {
  name              = "/aws/bedrock/agentcore/${var.agent_runtime_name}"
  retention_in_days = 90

  tags = {
    Name    = "${var.project_name}-logs"
    Project = var.project_name
  }
}

# ─── AgentCore Runtime ───
# Note: As of June 2026, the AgentCore Runtime resource is provisioned via AWS CLI
# because the Terraform AWS provider does not yet have a native resource for it.
# We use a null_resource with local-exec to call the API after all dependencies are ready.

resource "null_resource" "agentcore_runtime" {
  depends_on = [
    aws_vpc.main,
    aws_subnet.private,
    aws_security_group.agentcore,
    aws_iam_role.agentcore_runtime,
    aws_nat_gateway.main,
    aws_vpc_endpoint.ecr_dkr,
    aws_vpc_endpoint.logs,
    aws_cloudwatch_log_group.agentcore
  ]

  triggers = {
    runtime_name    = var.agent_runtime_name
    subnets         = join(",", aws_subnet.private[*].id)
    security_groups = aws_security_group.agentcore.id
    model           = var.foundation_model
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "[AgentCore] Creating runtime: ${var.agent_runtime_name}"

      # Check if runtime already exists
      EXISTING=$(aws bedrock-agentcore-control list-agent-runtimes \
        --region ${var.region} \
        --query "agentRuntimes[?agentRuntimeName=='${var.agent_runtime_name}'].agentRuntimeId" \
        --output text 2>/dev/null || echo "")

      if [ -n "$EXISTING" ] && [ "$EXISTING" != "None" ]; then
        echo "[AgentCore] Runtime already exists: $EXISTING"
      else
        aws bedrock-agentcore-control create-agent-runtime \
          --region ${var.region} \
          --agent-runtime-name "${var.agent_runtime_name}" \
          --network-configuration '{
            "networkMode": "VPC",
            "networkModeConfig": {
              "subnets": ${jsonencode(aws_subnet.private[*].id)},
              "securityGroups": ["${aws_security_group.agentcore.id}"]
            }
          }' || echo "[AgentCore] Create call returned non-zero — check console"
      fi
    EOT
  }
}
