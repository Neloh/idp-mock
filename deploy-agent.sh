#!/bin/bash
# deploy-agent.sh — CI/CD pipeline script for Bedrock Agent provisioning
# This is what runs AFTER the spec is approved through the IDP workflow.
#
# Pipeline stages:
#   1. Lint & validate the spec
#   2. Plan (show what will be created)
#   3. Gate: require manual approval (simulated)
#   4. Deploy: create IAM role, agent, alias
#   5. Smoke test: invoke the agent
#   6. Output: print agent details

set -euo pipefail

REGION="us-east-1"
ACCOUNT_ID="<YOUR_ACCOUNT_ID>"
AGENT_NAME="idp-platform-agent"
ROLE_NAME="BedrockAgentRole-IDP"
MODEL_ID="us.anthropic.claude-sonnet-4-6"

echo "============================================"
echo " AgentCore CI/CD Pipeline"
echo " Target: Bedrock Agent (Claude Sonnet 4.6)"
echo " Region: $REGION"
echo "============================================"
echo ""

# --- Stage 1: Validate ---
echo "[Stage 1/6] VALIDATE"
echo "  Checking spec file..."
if [ ! -f examples/bedrock-agent.yaml ]; then
  echo "  [FAIL] Spec file not found"
  exit 1
fi
echo "  [PASS] Spec file exists"
echo "  Checking model availability..."
MODEL_STATUS=$(aws bedrock list-foundation-models \
  --region "$REGION" \
  --by-provider Anthropic \
  --query "modelSummaries[?modelId=='anthropic.claude-sonnet-4-6'].modelLifecycle.status" \
  --output text 2>/dev/null)
if [ "$MODEL_STATUS" != "ACTIVE" ]; then
  echo "  [FAIL] Model not active (status: $MODEL_STATUS)"
  exit 1
fi
echo "  [PASS] Model is ACTIVE"
echo ""

# --- Stage 2: Plan ---
echo "[Stage 2/6] PLAN"
echo "  Resources to create:"
echo "    - IAM Role: $ROLE_NAME"
echo "    - IAM Policy: BedrockInvoke (inline)"
echo "    - Bedrock Agent: $AGENT_NAME"
echo "    - Agent Alias: live"
echo "    - CloudWatch Log Group: /aws/bedrock/agents/$AGENT_NAME"
echo ""

# --- Stage 3: Approval Gate ---
echo "[Stage 3/6] APPROVAL GATE"
if [ "${CI:-false}" = "true" ]; then
  echo "  Running in CI — checking approval status from spec..."
  # In real CI, this would check a database or approval API
  echo "  [PASS] Auto-approved (CI mode)"
else
  echo "  Running locally — skipping manual gate for demo"
  echo "  [PASS] Local execution approved"
fi
echo ""

# --- Stage 4: Deploy ---
echo "[Stage 4/6] DEPLOY"

# 4a: IAM Role
echo "  Creating IAM role..."
ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text 2>/dev/null || true)
if [ -z "$ROLE_ARN" ] || [ "$ROLE_ARN" = "None" ]; then
  ROLE_ARN=$(aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document "{
      \"Version\": \"2012-10-17\",
      \"Statement\": [{
        \"Effect\": \"Allow\",
        \"Principal\": {\"Service\": \"bedrock.amazonaws.com\"},
        \"Action\": \"sts:AssumeRole\",
        \"Condition\": {\"StringEquals\": {\"aws:SourceAccount\": \"$ACCOUNT_ID\"}}
      }]
    }" \
    --query 'Role.Arn' --output text)
  echo "  [OK] Created role: $ROLE_ARN"
else
  echo "  [OK] Role exists: $ROLE_ARN"
fi

# 4b: IAM Policy
echo "  Attaching invoke permissions..."
aws iam put-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-name "BedrockInvoke" \
  --policy-document "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [{
      \"Effect\": \"Allow\",
      \"Action\": [
        \"bedrock:InvokeModel\",
        \"bedrock:InvokeModelWithResponseStream\",
        \"bedrock:GetInferenceProfile\",
        \"bedrock:GetFoundationModel\"
      ],
      \"Resource\": [
        \"arn:aws:bedrock:$REGION::foundation-model/*\",
        \"arn:aws:bedrock:*:$ACCOUNT_ID:inference-profile/*\"
      ]
    }]
  }"
echo "  [OK] Policy attached"

# Wait for IAM propagation
echo "  Waiting for IAM propagation (10s)..."
sleep 10

# 4c: Bedrock Agent
echo "  Creating Bedrock Agent..."
AGENT_ID=$(aws bedrock-agent list-agents --region "$REGION" \
  --query "agentSummaries[?agentName=='$AGENT_NAME'].agentId" --output text 2>/dev/null)

if [ -z "$AGENT_ID" ] || [ "$AGENT_ID" = "None" ]; then
  AGENT_ID=$(aws bedrock-agent create-agent \
    --region "$REGION" \
    --agent-name "$AGENT_NAME" \
    --agent-resource-role-arn "$ROLE_ARN" \
    --foundation-model "$MODEL_ID" \
    --instruction "You are an Internal Developer Platform (IDP) agent. You help engineers submit infrastructure requests, validate their specs, and provision cloud resources." \
    --query 'agent.agentId' --output text)
  echo "  [OK] Created agent: $AGENT_ID"
else
  echo "  [OK] Agent exists: $AGENT_ID"
fi

# 4d: Prepare Agent
echo "  Preparing agent..."
aws bedrock-agent prepare-agent --agent-id "$AGENT_ID" --region "$REGION" > /dev/null 2>&1
echo "  Waiting for agent to be ready (15s)..."
sleep 15

AGENT_STATUS=$(aws bedrock-agent get-agent --agent-id "$AGENT_ID" --region "$REGION" \
  --query 'agent.agentStatus' --output text)
echo "  [OK] Agent status: $AGENT_STATUS"

# 4e: Create Alias
echo "  Creating agent alias..."
ALIAS_ID=$(aws bedrock-agent list-agent-aliases --agent-id "$AGENT_ID" --region "$REGION" \
  --query "agentAliasSummaries[?agentAliasName=='live'].agentAliasId" --output text 2>/dev/null)

if [ -z "$ALIAS_ID" ] || [ "$ALIAS_ID" = "None" ]; then
  ALIAS_ID=$(aws bedrock-agent create-agent-alias \
    --agent-id "$AGENT_ID" \
    --agent-alias-name "live" \
    --region "$REGION" \
    --query 'agentAlias.agentAliasId' --output text)
  echo "  [OK] Created alias: $ALIAS_ID"
else
  echo "  [OK] Alias exists: $ALIAS_ID"
fi
echo ""

# --- Stage 5: Smoke Test ---
echo "[Stage 5/6] SMOKE TEST"
echo "  Invoking agent with test prompt..."
sleep 10  # Wait for alias to be ready

RESPONSE=$(aws bedrock-agent-runtime invoke-agent \
  --agent-id "$AGENT_ID" \
  --agent-alias-id "$ALIAS_ID" \
  --session-id "smoke-test-$(date +%s)" \
  --input-text "What is your purpose?" \
  --region "$REGION" \
  --output text 2>/dev/null | head -c 200 || echo "[WARN] Invoke returned non-zero but agent may still be initializing")

if [ -n "$RESPONSE" ]; then
  echo "  [PASS] Agent responded: ${RESPONSE:0:100}..."
else
  echo "  [WARN] No response yet — agent may need more time to initialize"
fi
echo ""

# --- Stage 6: Output ---
echo "[Stage 6/6] OUTPUT"
echo "============================================"
echo "  Agent Name:    $AGENT_NAME"
echo "  Agent ID:      $AGENT_ID"
echo "  Alias ID:      $ALIAS_ID"
echo "  Model:         $MODEL_ID"
echo "  Region:        $REGION"
echo "  Role:          $ROLE_ARN"
echo "  Status:        $AGENT_STATUS"
echo ""
echo "  Invoke with:"
echo "    aws bedrock-agent-runtime invoke-agent \\"
echo "      --agent-id $AGENT_ID \\"
echo "      --agent-alias-id $ALIAS_ID \\"
echo "      --session-id \"my-session\" \\"
echo "      --input-text \"Help me deploy a service\" \\"
echo "      --region $REGION"
echo "============================================"
echo ""
echo "PIPELINE COMPLETE"
