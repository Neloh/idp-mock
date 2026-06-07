"""AgentCore Provisioner — simulates infrastructure creation."""
import argparse
import uuid
import time
from models import RequestStatus, InfraState
from store import load_request, update_status, save_infra


def mock_resource_id(prefix: str) -> str:
    return f"{prefix}-{uuid.uuid4().hex[:8]}"


def provision(request_id: str) -> InfraState:
    """Simulates the provisioning pipeline step by step."""
    req = load_request(request_id)

    if req.status != RequestStatus.APPROVED:
        raise RuntimeError(f"Request {request_id} is not approved (status: {req.status.value})")

    update_status(request_id, RequestStatus.PROVISIONING)
    spec = req.spec

    print(f"[PROVISIONER] Starting provisioning for: {spec.name}")
    print(f"[PROVISIONER] VPC: {spec.vpc_id}")

    # Step 1: Security Group
    sg_id = mock_resource_id("sg")
    print(f"  ✓ Created Security Group: {sg_id}")

    # Step 2: Target Group
    tg_arn = f"arn:aws:elasticloadbalancing:af-south-1:123456789:targetgroup/{spec.name}-tg/{uuid.uuid4().hex[:12]}"
    print(f"  ✓ Created Target Group: {tg_arn}")

    # Step 3: Load Balancer
    alb_arn = f"arn:aws:elasticloadbalancing:af-south-1:123456789:loadbalancer/app/{spec.name}-alb/{uuid.uuid4().hex[:12]}"
    alb_dns = f"{spec.name}-alb-{uuid.uuid4().hex[:8]}.af-south-1.elb.amazonaws.com"
    print(f"  ✓ Created ALB: {alb_dns}")

    # Step 4: ECS Cluster + Service
    cluster = f"{spec.team}-cluster"
    ecs_service = f"arn:aws:ecs:af-south-1:123456789:service/{cluster}/{spec.name}"
    print(f"  ✓ Created ECS Service: {spec.name} (min={spec.replicas_min}, max={spec.replicas_max})")

    # Step 5: CloudWatch Log Group
    log_group = f"/ecs/{spec.team}/{spec.name}"
    print(f"  ✓ Created Log Group: {log_group}")

    # Step 6: WAF
    if spec.waf_enabled:
        print(f"  ✓ Attached WAF Web ACL to ALB")

    # Save infra state
    infra = InfraState(
        request_id=request_id,
        security_group_id=sg_id,
        target_group_arn=tg_arn,
        load_balancer_arn=alb_arn,
        load_balancer_dns=alb_dns,
        ecs_cluster=cluster,
        ecs_service=ecs_service,
        log_group=log_group,
    )
    save_infra(infra)
    update_status(request_id, RequestStatus.DEPLOYED)

    print(f"\n[PROVISIONER] ✅ Deployment complete!")
    print(f"  Endpoint: https://{alb_dns}")
    print(f"  Logs:     {log_group}")
    print(f"  Status:   DEPLOYED")
    return infra


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="AgentCore Provisioner")
    parser.add_argument("--request-id", required=True, help="Request ID to provision")
    args = parser.parse_args()
    provision(args.request_id)
