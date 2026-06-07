# Examples

This folder holds sample YAML specs that engineers fill out when requesting infrastructure.

## Files

- **trade-service.yaml** — A trade event processing service running on ECS Fargate behind an internal ALB.

## How to Use

Copy a file, fill in your details, then submit:

```bash
python platform_cli.py submit --spec examples/trade-service.yaml
```

## What Goes in a Spec

| Field | What It Means |
|-------|--------------|
| `name` | Your service name (e.g. "order-processor") |
| `team` | Your team name |
| `vpc_id` | The VPC your service will live in (must already exist) |
| `runtime` | Always "docker" for now |
| `port` | The port your container listens on |
| `cpu` / `memory` | How much compute your container needs |
| `image` | Your Docker image URI from ECR |
| `replicas min/max` | How many copies to run (min 2 for high availability) |
| `gateway type` | "alb" (load balancer) or "api-gateway" |
| `wafEnabled` | Must be true if the service is public-facing |
