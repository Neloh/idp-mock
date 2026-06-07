"""Data models for the IDP."""
from dataclasses import dataclass, field
from enum import Enum
from typing import Optional
import uuid
from datetime import datetime, timezone


class RequestStatus(Enum):
    SUBMITTED = "submitted"
    VALIDATED = "validated"
    SECURITY_REVIEW = "security_review"
    APPROVED = "approved"
    PROVISIONING = "provisioning"
    DEPLOYED = "deployed"
    REJECTED = "rejected"


@dataclass
class ServiceSpec:
    name: str
    team: str
    requested_by: str
    runtime: str  # docker
    port: int
    cpu: str
    memory: str
    image: str
    vpc_id: str
    subnet_type: str
    gateway_type: str  # alb | api-gateway
    public: bool
    waf_enabled: bool
    replicas_min: int
    replicas_max: int


@dataclass
class PlatformRequest:
    spec: ServiceSpec
    request_id: str = field(default_factory=lambda: f"REQ-{uuid.uuid4().hex[:6].upper()}")
    status: RequestStatus = RequestStatus.SUBMITTED
    created_at: str = field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    security_approved: bool = False
    platform_approved: bool = False
    rejection_reason: Optional[str] = None


@dataclass
class InfraState:
    request_id: str
    security_group_id: str = ""
    target_group_arn: str = ""
    load_balancer_arn: str = ""
    load_balancer_dns: str = ""
    ecs_cluster: str = ""
    ecs_service: str = ""
    log_group: str = ""
