# Interview Notes — IDP, Cloud Architecture, and Andile Context

## AWS Well-Architected Framework Pillars Mapped to Our IDP

### 1. OPERATIONAL EXCELLENCE
"How do you run and monitor systems to deliver business value?"

What we built:
- CI/CD pipeline (Jenkins/GitHub Actions) — repeatable, automated deployments
- Environment resolver — same spec deploys consistently to dev/staging/prod
- Observability — CloudWatch logs, health checks (/ping endpoint)
- Infrastructure as Code — Terraform, not manual clicks

Andile context:
- Capital markets trade systems need zero-downtime deployments
- Audit trail: who submitted, who approved, what was deployed, when
- Runbooks generated from specs — every service looks the same operationally
- Change management compliance: pipeline enforces approval before production

---

### 2. SECURITY
"How do you protect information, systems, and assets?"

What we built:
- Security review gate — mandatory before any deployment
- Least-privilege IAM — AgentCore role can only invoke models, pull images, write logs
- WAF enforced on public endpoints
- Private subnets — compute never exposed to internet
- Security groups — HTTPS egress only, no inbound
- Encryption at rest + in transit (non-negotiable)
- Secrets in Secrets Manager (never in env vars)

Andile context:
- Banks handle PII, trade data, regulatory-sensitive information
- MiFID II, POPIA, Basel III require audit trails and access control
- No engineer can bypass security gate — platform enforces it
- VPC isolation: trade systems cannot reach internet directly
- Encryption is a regulatory requirement, not optional

---

### 3. RELIABILITY
"How do you ensure a system performs its intended function correctly?"

What we built:
- Minimum 2 replicas across 2 AZs (enforced by validator)
- Health checks with automatic replacement
- Load balancer routes around failures
- AgentCore manages container lifecycle (restart on crash)
- Existing VPC reuse — no single-tenant network sprawl

Andile context:
- Trading platforms cannot go down during market hours
- Multi-AZ: if a data centre fails, trades still execute
- Auto-scaling: Black Friday of trading (market volatility) handled automatically
- Disaster recovery: rebuild from spec (infrastructure is code, not snowflakes)

---

### 4. PERFORMANCE EFFICIENCY
"How do you use computing resources efficiently?"

What we built:
- Right-sizing through spec (engineer declares CPU/memory needs)
- Auto-scaling from min to max based on demand
- Serverless where possible (AgentCore manages compute)
- VPC endpoints — avoid NAT gateway latency for AWS service calls
- ARM64 containers — better price/performance

Andile context:
- Trade execution latency matters (microseconds in some cases)
- Right-sizing prevents overprovisioning (capital markets != always peak load)
- Burst capacity for market open/close spikes
- Cost efficiency: banks pay per trade margin, infra cost eats into that

---

### 5. COST OPTIMIZATION
"How do you avoid unnecessary costs?"

What we built:
- Reuse existing VPC (no per-service VPC = no per-service NAT Gateway at $30/month each)
- VPC endpoints instead of NAT for AWS traffic
- Auto-scaling down to minimum when idle
- Shared platform infra — one pipeline serves all teams
- Serverless compute (pay per invocation, not per hour)

Andile context:
- Banks care deeply about TCO (Total Cost of Ownership)
- Andile's value prop is "reduce TCO for Trade, Treasury, Risk"
- Platform team as shared service = amortized cost across teams
- Show clients: "your 50 services share one VPC, one pipeline, one platform team"

---

### 6. SUSTAINABILITY
"How do you minimize environmental impact?"

What we built:
- ARM64 (lower power consumption than x86)
- Auto-scale to zero when not in use
- Shared infrastructure (less idle compute)
- Right-sized containers (no 4GB for a health check service)

---

## IDP Layers Mapped to Andile's Business

```
ANDILE'S CLIENTS (Banks)          ANDILE'S ROLE               AWS
────────────────────────          ──────────────              ───
Bank engineers write              Andile builds and           AWS provides
trade/risk/treasury apps          operates the platform       the cloud infra

    DEVELOPER LAYER               PLATFORM LAYER              INFRA LAYER
    ───────────────               ──────────────              ───────────
    Submit YAML spec              Validate, secure,           VPC, ECS, ALB,
    Write container code          approve, deploy             AgentCore, IAM
    Push to git                   Own the pipeline            Managed services
```

Andile sits in the PLATFORM LAYER — that is literally their business:
"Helping banks run their Trade, Treasury, Risk more effectively and reduce TCO"

---

## Key Tools and Where They Fit

| Tool | Layer | Purpose | Andile Relevance |
|------|-------|---------|-----------------|
| Terraform | Platform | Infrastructure as Code | Repeatable, auditable infra |
| Jenkins/GitLab | Platform | CI/CD pipeline | Enforces process, approval gates |
| ArgoCD | Platform | GitOps for K8s | Drift detection (regulatory need) |
| Docker | Developer | Package application | Consistent across environments |
| AWS AgentCore | Infra | Managed agent compute | AI-powered trade assistants |
| Bedrock | Infra | Foundation models | Risk analysis, document processing |
| DynamoDB | Infra | NoSQL database | Trade events, positions, real-time data |
| ECS Fargate | Infra | Serverless containers | No host management for bank teams |
| ALB + WAF | Infra | Gateway + protection | TLS termination, DDoS protection |
| CloudWatch | Infra | Observability | Audit logs, compliance monitoring |

---

## How to Explain the Demo (30-second version)

"I built an Internal Developer Platform that lets engineers at a bank submit a
YAML spec saying what they need — a container on port 8080 with 2 replicas.
The platform validates it, runs a security check, and if approved, provisions
everything automatically: security group, load balancer, compute, logging.
Same spec works for dev, staging, prod — you just change the target environment.
The infra is Terraform, the pipeline is Jenkins, and I deployed a real AgentCore
Runtime in AWS to prove it works end to end."

---

## Questions They Might Ask + Answers

Q: "How do you handle secrets?"
A: Secrets Manager, injected at runtime. Never in env vars, never in code, never in git.

Q: "How do you handle rollback?"
A: Revert the git commit or re-deploy previous container tag. Infra is stateless.

Q: "What if someone changes infra manually?"
A: Terraform drift detection on next plan. ArgoCD if K8s. Pipeline is source of truth.

Q: "How do you handle multi-tenancy?"
A: Separate VPCs per business unit, shared platform layer. Resource-based policies.

Q: "What about compliance/audit?"
A: Every deployment goes through pipeline = logged. Spec + approval = audit trail.
   CloudTrail for API-level audit. CloudWatch for runtime audit.

Q: "On-prem vs cloud?"
A: Same IDP pattern. Swap provisioner backend: Terraform for AWS, Ansible for on-prem,
   Crossplane for multi-cloud. Engineer spec stays identical.

Q: "Why not just give engineers AWS console access?"
A: Security risk, no consistency, no audit trail, no guardrails. The platform
   gives them speed WITH compliance. That is Andile's entire value proposition.
