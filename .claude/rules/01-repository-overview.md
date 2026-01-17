# Repository Overview

This is a Terraform-based repository containing production-ready GCP architecture patterns with comprehensive observability.

## Architecture Patterns

### Event-Driven (`architectures/event-driven/gcp/`) - Implemented
- Pub/Sub + Cloud Run for push-based message delivery
- Dead Letter Queue, automatic retry logic
- Push subscriptions with Cloud Run integration
- Modular design with separate modules for each component

### Future Patterns (Planned)
- **Microservices on GKE**: GKE Autopilot with Workload Identity
- **Workflow Batch**: Cloud Scheduler → Workflows → Cloud Run Job pipeline

## Directory Structure

```
tf-observable-architecture-patterns/
├── architectures/               # Architecture pattern implementations
│   └── event-driven/
│       ├── gcp/
│       │   ├── *.tf            # Root configuration files
│       │   ├── modules/        # Modular components
│       │   │   ├── cloudrun/
│       │   │   ├── iam_bindings/
│       │   │   ├── monitoring/
│       │   │   ├── observability/
│       │   │   ├── pubsub/
│       │   │   └── service_accounts/
│       │   └── tests/     # Terraform native tests (.tftest.hcl)
│       
├── bootstrap/gcp/               # Bootstrap resources
│   ├── github-actions-auth/     # Workload Identity Federation setup
│   ├── secrets/                 # Secret Manager for CI/CD secrets
│   └── terraform-state/         # GCS state bucket creation
├── .github/workflows/           # CI/CD pipelines
├── scripts/                     # Utility scripts
└── docs/                        # Architecture documentation
```

## Configuration Files

Each architecture pattern has these root-level files:

| File | Purpose |
|------|---------|
| `main.tf` | Module calls and resource orchestration |
| `variables.tf` | Input variable definitions |
| `outputs.tf` | Output values |
| `providers.tf` | Provider configuration |
| `versions.tf` | Terraform and provider versions |
| `backend.tf` | Backend configuration (partial config) |
| `terraform.tfvars.example` | Example variable values |
| `secrets.auto.tfvars.example` | Example sensitive variable values |
| `backend.hcl.example` | Example backend configuration |
| `dev.auto.tfvars` | Dev environment variable overrides |
