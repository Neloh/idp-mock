"""Validates a service spec before it enters the review pipeline."""
from models import ServiceSpec

ALLOWED_RUNTIMES = {"docker"}
ALLOWED_GATEWAYS = {"alb", "api-gateway"}
MAX_CPU = 4096
MAX_MEMORY = 30720


def validate_spec(spec: ServiceSpec) -> list[str]:
    """Returns a list of validation errors. Empty list means valid."""
    errors = []

    if not spec.name:
        errors.append("Service name is required")
    if not spec.vpc_id:
        errors.append("Existing VPC ID is required — platform does not create new VPCs")
    if spec.runtime not in ALLOWED_RUNTIMES:
        errors.append(f"Runtime must be one of: {ALLOWED_RUNTIMES}")
    if spec.gateway_type not in ALLOWED_GATEWAYS:
        errors.append(f"Gateway type must be one of: {ALLOWED_GATEWAYS}")
    if not spec.image:
        errors.append("Container image URI is required")
    if int(spec.cpu) > MAX_CPU:
        errors.append(f"CPU cannot exceed {MAX_CPU} units")
    if int(spec.memory) > MAX_MEMORY:
        errors.append(f"Memory cannot exceed {MAX_MEMORY} MB")
    if spec.replicas_min < 2:
        errors.append("Minimum replicas must be >= 2 for high availability")
    if spec.replicas_max < spec.replicas_min:
        errors.append("Max replicas must be >= min replicas")

    return errors


def security_check(spec: ServiceSpec) -> list[str]:
    """Simulates security review gate. Returns list of concerns."""
    concerns = []

    if spec.public and not spec.waf_enabled:
        concerns.append("BLOCKED: Public-facing services must have WAF enabled")
    if spec.subnet_type == "public":
        concerns.append("WARNING: Compute should run in private subnets — justify public placement")
    if "*" in spec.image:
        concerns.append("BLOCKED: Wildcard image references not allowed")

    return concerns
