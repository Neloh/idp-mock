# Tests

Automated tests that verify the IDP workflow works correctly.

## How to Run

```bash
python -m pytest tests/ -v
```

## What Each Test Checks

| Test | What It Verifies |
|------|-----------------|
| `test_full_e2e_flow` | Submit a valid spec, gets approved, provisions infra, status becomes DEPLOYED |
| `test_validation_rejects_missing_vpc` | A spec without a VPC ID is rejected (we reuse existing networks, never create new ones) |
| `test_security_blocks_public_without_waf` | A public-facing service without WAF protection is blocked by the security gate |

## Why These Tests Matter

These represent the guardrails that protect production:

- **VPC must exist** — prevents network sprawl and ensures proper segmentation
- **WAF required for public** — prevents exposing services without DDoS/attack protection
- **Full flow works** — proves the pipeline from submission to deployed service is correct

## Adding More Tests

Good things to test next:
- Spec with CPU above the limit gets rejected
- Spec with replicas_min less than 2 gets rejected (HA requirement)
- Provisioner refuses to run if the request is not in APPROVED status
- Multiple services can be provisioned without conflicts
