# Tests

Automated tests that verify the IDP workflow works correctly.

## How to Run

```bash
python -m pytest tests/ -v
```

## What's Tested

| Test | What It Checks |
|------|---------------|
| `test_full_e2e_flow` | Submit a valid spec → gets approved → provisions infra → status is DEPLOYED |
| `test_validation_rejects_missing_vpc` | A spec without a VPC ID is rejected (we don't create new VPCs) |
| `test_security_blocks_public_without_waf` | A public-facing service without WAF protection is blocked |

## Adding More Tests

Good things to test next:
- Spec with CPU above the limit → rejected
- Spec with replicas_min < 2 → rejected
- Provisioner rejects a request that hasn't been approved
