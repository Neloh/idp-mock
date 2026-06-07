# End-to-End Architecture — Internal Developer Platform (IDP)

## How an IDP Works (What You'd Explain in an Interview)

An IDP is a self-service layer that sits between engineers and infrastructure.
Engineers describe WHAT they need, the platform handles HOW it gets built.

---

## E2E Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                              INTERNAL DEVELOPER PLATFORM                                  │
│                              (AgentCore PaaS Workflow)                                    │
└─────────────────────────────────────────────────────────────────────────────────────────┘

 ENGINEER                    PLATFORM                         INFRASTRUCTURE
 ───────                     ────────                         ──────────────

 ┌────────────┐
 │ 1. DISCUSS │ Engineer meets Platform team
 │    & PLAN  │ → Agree on service requirements
 └─────┬──────┘ → Security posture decided
       │
       ▼
 ┌────────────┐        ┌─────────────────┐
 │ 2. SUBMIT  │───────▶│  platform_cli   │
 │    SPEC    │  YAML  │  (submit)       │
 └────────────┘        └────────┬────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │ 3. VALIDATE     │
                       │ • Name exists?  │
                       │ • VPC provided? │
                       │ • Sizing valid? │
                       │ • Min 2 replica?│
                       └────────┬────────┘
                                │ PASS
                                ▼
                       ┌─────────────────┐
                       │ 4. SECURITY     │
                       │    REVIEW       │
                       │ • WAF on public?│
                       │ • Private subs? │
                       │ • No wildcards? │
                       └────────┬────────┘
                                │ PASS
                                ▼
                       ┌─────────────────┐
                       │ 5. APPROVE      │
                       │ security: PASS  │
                       │ platform: PASS  │
                       └────────┬────────┘
                                │
                                ▼
                       ┌─────────────────┐         ┌─────────────────────────────────┐
                       │ 6. PROVISION    │────────▶│         AWS INFRASTRUCTURE       │
                       │  (provisioner)  │         │                                  │
                       │                 │         │  ┌───────────────────────────┐   │
                       │ • Resolve VPC   │         │  │     EXISTING VPC          │   │
                       │ • Create SG     │────────▶│  │                           │   │
                       │ • Create TG     │────────▶│  │  ┌─────────────────────┐  │   │
                       │ • Create ALB    │────────▶│  │  │  Public Subnets     │  │   │
                       │ • Create ECS Svc│────────▶│  │  │  ┌───────────────┐  │  │   │
                       │ • Attach WAF    │────────▶│  │  │  │  ALB + WAF    │  │  │   │
                       │ • Create Logs   │────────▶│  │  │  └───────┬───────┘  │  │   │
                       └────────┬────────┘         │  │  └──────────┼──────────┘  │   │
                                │                  │  │             │              │   │
                                │                  │  │  ┌──────────▼──────────┐  │   │
                                │                  │  │  │  Private Subnets    │  │   │
                                │                  │  │  │  ┌──────────────┐   │  │   │
                                │                  │  │  │  │ Target Group │   │  │   │
                                │                  │  │  │  │ ┌────┐┌────┐│   │  │   │
                                │                  │  │  │  │ │ECS ││ECS ││   │  │   │
                                │                  │  │  │  │ │Task││Task││   │  │   │
                                │                  │  │  │  │ └────┘└────┘│   │  │   │
                                │                  │  │  │  └──────────────┘   │  │   │
                                │                  │  │  └─────────────────────┘  │   │
                                │                  │  └───────────────────────────┘   │
                                │                  └─────────────────────────────────┘
                                ▼
                       ┌─────────────────┐
                       │ 7. DELIVER      │
                       │ • Endpoint URL  │──────▶ Engineer gets service running
                       │ • Log group     │
                       │ • Status: LIVE  │
                       └─────────────────┘
```

---

## Data Flow

```
YAML Spec ──▶ Validator ──▶ Security Gate ──▶ Approval ──▶ Provisioner ──▶ AWS Resources
                 │                │                              │
                 ▼                ▼                              ▼
            REJECTED         BLOCKED                    infrastructure/
            (fix & re-       (security                  {request-id}.json
             submit)          concern)                  (state record)
```

---

## What Makes This an IDP (Interview Talking Points)

| IDP Concept | How This Mock Demonstrates It |
|-------------|-------------------------------|
| **Self-service** | Engineer submits YAML, doesn't touch AWS console |
| **Golden path** | Standard topology: VPC → ALB → TG → ECS. Always the same. |
| **Guardrails** | Validation + security gates prevent misconfigurations |
| **Abstraction** | Engineer says "I need 2 replicas on port 8080" — platform figures out SG, TG, ALB, ECS |
| **Automation** | Provisioner creates all resources from a single approved spec |
| **Governance** | Security review is a mandatory gate — can't bypass |
| **Reproducibility** | Same spec = same infra every time |

---

## How This Relates to Real Tools

| This Mock | Production Equivalent |
|-----------|----------------------|
| `platform_cli.py` | Backstage (Spotify), Port, Humanitec, or custom portal |
| `validator.py` | OPA/Rego policies, Crossplane validation webhooks |
| `provisioner.py` | Terraform/CDK triggered by CI/CD, Crossplane controllers |
| `store.py` | DynamoDB, PostgreSQL, or Backstage catalog |
| YAML spec | Backstage software template, Crossplane XR claim |
| Security gate | Automated policy checks + manual approval workflow |

---

## Why Build an IDP at a Financial Institution (Andile Context)

Capital markets teams need:
1. **Speed** — traders need services deployed fast for market conditions
2. **Compliance** — every deployment must meet regulatory security standards
3. **Consistency** — 50 services should all look the same operationally
4. **Auditability** — who requested what, who approved, what was deployed, when

An IDP gives you all four without sacrificing developer velocity.
