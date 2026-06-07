# IDP Mock — Internal Developer Platform

> A simple working example of how a Platform Engineering team can let developers
> request infrastructure through a form, review it for security, and automatically
> set everything up.

![Demo](docs/demo.gif)

---

## What Is This?

This is a **mock Internal Developer Platform (IDP)**. It shows the full process:

1. **Engineer fills in a YAML form** saying what they need (container, port, size, etc.)
2. **Platform validates it** — checks nothing is missing or misconfigured
3. **Security review runs** — blocks anything dangerous (e.g. public endpoint with no WAF)
4. **Provisioner creates the infra** — security group, load balancer, target group, ECS service
5. **Engineer gets their endpoint** — service is live

The infrastructure is simulated (no real AWS calls), but the logic and workflow are real.

---

## Quick Start

```bash
# Install dependencies
pip install -r requirements.txt

# Run the full demo
./demo.sh

# Or step by step:
python platform_cli.py submit --spec examples/trade-service.yaml
python provisioner.py --request-id <REQUEST_ID>

# Run tests
python -m pytest tests/ -v
```

---

## Project Layout

```
├── platform_cli.py          # What engineers use to submit requests
├── provisioner.py           # What creates the infrastructure after approval
├── validator.py             # Rules that check if the spec is valid and secure
├── models.py                # Data structures (request, infra state)
├── store.py                 # Saves request/infra state as JSON files
├── demo.sh                  # Script to run the full demo (for GIF recording)
├── examples/                # Sample request specs
│   └── trade-service.yaml
├── tests/                   # Automated tests
│   └── test_e2e.py
├── docs/                    # Architecture diagrams and docs
│   └── e2e-architecture.md
├── requests/                # (created at runtime) submitted requests
└── infrastructure/          # (created at runtime) provisioned infra state
```

---

## How to Record the Demo GIF

```bash
# Option 1: asciinema + agg
asciinema rec demo.cast
./demo.sh
# press Ctrl+D to stop
agg demo.cast docs/demo.gif

# Option 2: terminalizer
terminalizer record demo
# run ./demo.sh inside the recording
terminalizer render demo -o docs/demo.gif
```

---

## Environment Placeholders

This mock uses placeholder values. In a real setup, replace these:

| Placeholder | Real Value |
|-------------|-----------|
| `vpc-0abc123def456` | Your actual VPC ID |
| `123456789` | Your AWS account ID |
| `af-south-1` | Your AWS region |
| `123456789.dkr.ecr...` | Your ECR image URI |
| JSON file store | DynamoDB, PostgreSQL, or your DB of choice |
| `platform_cli.py` | Web UI (Backstage, Port) or API |
| `provisioner.py` | Terraform, CDK, or Crossplane |

---

## What This Demonstrates

- **Self-service**: Engineers describe what they want, platform handles the how
- **Security by default**: WAF, private subnets, encryption — enforced automatically
- **Golden path**: Every service gets the same proven architecture
- **Auditability**: Every request is saved with who asked, who approved, and what was built
- **Capital markets ready**: VPC reuse (shared bank network), compliance gates, HA (min 2 replicas)
