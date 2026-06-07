"""End-to-end test: submit a spec and provision infrastructure."""
import os
import sys
import json

sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from models import RequestStatus
from platform_cli import load_spec_from_yaml, submit
from provisioner import provision
from store import load_request, load_infra


EXAMPLE_SPEC = os.path.join(os.path.dirname(os.path.dirname(__file__)), "examples", "trade-service.yaml")


def test_full_e2e_flow():
    """Test: submit spec → validate → approve → provision → deployed."""
    # Submit
    req = submit(EXAMPLE_SPEC)
    assert req.status == RequestStatus.APPROVED
    assert req.security_approved is True
    assert req.platform_approved is True

    # Provision
    infra = provision(req.request_id)
    assert infra.security_group_id.startswith("sg-")
    assert "targetgroup" in infra.target_group_arn
    assert "loadbalancer" in infra.load_balancer_arn
    assert infra.load_balancer_dns.endswith("elb.amazonaws.com")
    assert infra.ecs_service != ""
    assert infra.log_group.startswith("/ecs/")

    # Verify final state
    final_req = load_request(req.request_id)
    assert final_req.status == RequestStatus.DEPLOYED


def test_validation_rejects_missing_vpc():
    """Test: spec without VPC ID fails validation."""
    from models import ServiceSpec
    from validator import validate_spec

    spec = ServiceSpec(
        name="bad-service",
        team="test",
        requested_by="test",
        runtime="docker",
        port=8080,
        cpu="512",
        memory="1024",
        image="some-image:latest",
        vpc_id="",  # Missing!
        subnet_type="private",
        gateway_type="alb",
        public=False,
        waf_enabled=True,
        replicas_min=2,
        replicas_max=4,
    )
    errors = validate_spec(spec)
    assert any("VPC" in e for e in errors)


def test_security_blocks_public_without_waf():
    """Test: public service without WAF is blocked."""
    from models import ServiceSpec
    from validator import security_check

    spec = ServiceSpec(
        name="exposed-service",
        team="test",
        requested_by="test",
        runtime="docker",
        port=8080,
        cpu="512",
        memory="1024",
        image="some-image:latest",
        vpc_id="vpc-123",
        subnet_type="private",
        gateway_type="alb",
        public=True,
        waf_enabled=False,  # Public + no WAF = blocked
        replicas_min=2,
        replicas_max=4,
    )
    concerns = security_check(spec)
    assert any("BLOCKED" in c for c in concerns)
