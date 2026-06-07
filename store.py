"""Simple JSON file store — simulates a database for requests and infra state."""
import json
import os
from models import PlatformRequest, RequestStatus, InfraState, ServiceSpec

REQUESTS_DIR = os.path.join(os.path.dirname(__file__), "requests")
INFRA_DIR = os.path.join(os.path.dirname(__file__), "infrastructure")

os.makedirs(REQUESTS_DIR, exist_ok=True)
os.makedirs(INFRA_DIR, exist_ok=True)


def save_request(req: PlatformRequest) -> str:
    path = os.path.join(REQUESTS_DIR, f"{req.request_id}.json")
    data = {
        "request_id": req.request_id,
        "status": req.status.value,
        "created_at": req.created_at,
        "security_approved": req.security_approved,
        "platform_approved": req.platform_approved,
        "rejection_reason": req.rejection_reason,
        "spec": req.spec.__dict__,
    }
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
    return path


def load_request(request_id: str) -> PlatformRequest:
    path = os.path.join(REQUESTS_DIR, f"{request_id}.json")
    with open(path) as f:
        data = json.load(f)
    spec = ServiceSpec(**data["spec"])
    return PlatformRequest(
        spec=spec,
        request_id=data["request_id"],
        status=RequestStatus(data["status"]),
        created_at=data["created_at"],
        security_approved=data["security_approved"],
        platform_approved=data["platform_approved"],
        rejection_reason=data["rejection_reason"],
    )


def update_status(request_id: str, status: RequestStatus, **kwargs):
    req = load_request(request_id)
    req.status = status
    for k, v in kwargs.items():
        setattr(req, k, v)
    save_request(req)
    return req


def save_infra(infra: InfraState) -> str:
    path = os.path.join(INFRA_DIR, f"{infra.request_id}.json")
    with open(path, "w") as f:
        json.dump(infra.__dict__, f, indent=2)
    return path


def load_infra(request_id: str) -> InfraState:
    path = os.path.join(INFRA_DIR, f"{request_id}.json")
    with open(path) as f:
        data = json.load(f)
    return InfraState(**data)
