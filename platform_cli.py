"""Engineer-facing CLI to submit infrastructure requests."""
import argparse
import yaml
import sys
from models import ServiceSpec, PlatformRequest, RequestStatus
from validator import validate_spec, security_check
from store import save_request, update_status


def load_spec_from_yaml(path: str) -> ServiceSpec:
    with open(path) as f:
        data = yaml.safe_load(f)

    s = data["spec"]
    return ServiceSpec(
        name=data["metadata"]["name"],
        team=data["metadata"]["team"],
        requested_by=data["metadata"]["requestedBy"],
        runtime=s["service"]["runtime"],
        port=s["service"]["port"],
        cpu=s["container"]["cpu"],
        memory=s["container"]["memory"],
        image=s["container"]["image"],
        vpc_id=s["networking"]["existingVpcId"],
        subnet_type=s["networking"]["subnetType"],
        gateway_type=s["gateway"]["type"],
        public=s["gateway"]["public"],
        waf_enabled=s["gateway"]["wafEnabled"],
        replicas_min=s["service"]["replicas"]["min"],
        replicas_max=s["service"]["replicas"]["max"],
    )


def submit(spec_path: str) -> PlatformRequest:
    """Full submission flow: parse → validate → security check → save."""
    print(f"[IDP] Loading spec from: {spec_path}")
    spec = load_spec_from_yaml(spec_path)

    # Step 1: Validate
    print(f"[IDP] Validating spec for service: {spec.name}")
    errors = validate_spec(spec)
    if errors:
        print("[IDP] [FAILED] Validation FAILED:")
        for e in errors:
            print(f"       - {e}")
        sys.exit(1)

    req = PlatformRequest(spec=spec, status=RequestStatus.VALIDATED)
    save_request(req)
    print(f"[IDP] [PASS] Validation passed — Request ID: {req.request_id}")

    # Step 2: Security check
    print("[IDP] Running security review...")
    concerns = security_check(spec)
    blocked = [c for c in concerns if c.startswith("BLOCKED")]

    if blocked:
        req.status = RequestStatus.REJECTED
        req.rejection_reason = "; ".join(blocked)
        save_request(req)
        print("[IDP] [BLOCKED] Security review BLOCKED:")
        for c in concerns:
            print(f"       - {c}")
        sys.exit(1)

    if concerns:
        print("[IDP] [WARNING] Security warnings (manual review needed):")
        for c in concerns:
            print(f"       - {c}")

    # Step 3: Approve (simulated — in reality platform team would review)
    req.security_approved = True
    req.platform_approved = True
    req.status = RequestStatus.APPROVED
    save_request(req)
    print(f"[IDP] [PASS] Approved — ready for provisioning")
    print(f"[IDP] Run: python provisioner.py --request-id {req.request_id}")
    return req


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="IDP Platform CLI")
    sub = parser.add_subparsers(dest="command")

    submit_cmd = sub.add_parser("submit", help="Submit an infrastructure request")
    submit_cmd.add_argument("--spec", required=True, help="Path to YAML spec file")

    args = parser.parse_args()
    if args.command == "submit":
        submit(args.spec)
    else:
        parser.print_help()
