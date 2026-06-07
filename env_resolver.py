"""Resolves environment config from the spec's target environment."""
import yaml
import os

CONFIG_PATH = os.path.join(os.path.dirname(__file__), "environments", "config.yaml")


def load_env_config(env_name: str) -> dict:
    """Load environment config by name. Returns all infra params for that env."""
    with open(CONFIG_PATH) as f:
        config = yaml.safe_load(f)

    envs = config.get("environments", {})
    if env_name not in envs:
        raise ValueError(f"Unknown environment: {env_name}. Available: {list(envs.keys())}")

    return envs[env_name]


def resolve_spec(spec_path: str, env_name: str) -> dict:
    """Merges engineer spec + environment config into deployment params."""
    with open(spec_path) as f:
        spec = yaml.safe_load(f)

    env = load_env_config(env_name)

    return {
        "service_name": spec["metadata"]["name"],
        "team": spec["metadata"]["team"],
        "region": env["region"],
        "vpc_id": env["vpc_id"],
        "subnets": env["subnets"],
        "security_group": env["security_group"],
        "ecr_repo": env["ecr_repo"],
        "role_arn": env["role_arn"],
        "approval_required": env["approval_required"],
        "runtime": spec["spec"]["service"]["runtime"],
        "port": spec["spec"]["service"]["port"],
        "replicas_min": spec["spec"]["service"]["replicas"]["min"],
        "replicas_max": spec["spec"]["service"]["replicas"]["max"],
    }


if __name__ == "__main__":
    import sys
    if len(sys.argv) != 3:
        print("Usage: python env_resolver.py <spec.yaml> <env_name>")
        print("  Example: python env_resolver.py examples/trade-service.yaml dev")
        sys.exit(1)

    import json
    params = resolve_spec(sys.argv[1], sys.argv[2])
    print(json.dumps(params, indent=2))
