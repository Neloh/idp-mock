# Internal Developer Platform (IDP) — Mock Environment
# PaaS for Capital Markets Hosting

A lightweight mock IDP demonstrating how engineers at a financial institution
submit infrastructure requests and how a platform team provisions environments
through an automated pipeline.

## What This Demonstrates

```
Engineer submits spec → Validation → Security review → Automated provisioning → Endpoints delivered
```

## Quick Start

```bash
# Install dependencies
pip install -r requirements.txt

# Run the platform CLI (submit a request)
python platform_cli.py submit --spec examples/trade-service.yaml

# Run the provisioner (simulates infra creation)
python provisioner.py --request-id REQ-001

# Run E2E test
python -m pytest tests/ -v
```

## Architecture

See `docs/e2e-architecture.md` for the full end-to-end diagram.

## Project Structure

```
├── platform_cli.py          # Engineer-facing CLI to submit specs
├── provisioner.py           # AgentCore runtime that provisions infra
├── validator.py             # Spec validation logic
├── models.py                # Data models (request, infra state)
├── store.py                 # Simple JSON file store (mock DB)
├── examples/
│   └── trade-service.yaml   # Sample request spec
├── tests/
│   └── test_e2e.py          # End-to-end test
├── docs/
│   └── e2e-architecture.md  # Full E2E diagram
├── requests/                # Submitted requests land here
├── infrastructure/          # Provisioned infra state stored here
└── requirements.txt
```
