# Terraform GCP Observable Architecture Patterns

Production-ready GCP architecture patterns with Terraform and comprehensive observability.

## Features

- **Environment Isolation**: Separated state management via `.auto.tfvars` files
- **Modular Design**: Reusable Terraform modules per component
- **Production-Ready**: Security, monitoring, and alerting built-in
- **GitOps Support**: Automated deployment with GitHub Actions
- **Native Testing**: Terraform test framework (`terraform test`)

## Architecture Patterns

### Event-Driven Architecture (Implemented)

Event-driven system using Pub/Sub + Cloud Run.

- Push-based message delivery with Dead Letter Queue
- Automatic retry logic and error handling
- Comprehensive monitoring and alerting
- Details: [architectures/event-driven/gcp/](architectures/event-driven/gcp/)

### Future Patterns (Planned)

- **Microservices on GKE**: GKE Autopilot with Workload Identity
- **Workflow Batch**: Cloud Scheduler → Workflows → Cloud Run Job

## Project Structure

```
tf-observable-architecture-patterns/
├── architectures/               # Architecture pattern implementations
│   └── event-driven/gcp/
│       ├── *.tf                # Root configuration files
│       ├── dev.auto.tfvars     # Environment-specific values
│       ├── modules/            # Modular components
│       │   ├── artifact_registry/
│       │   ├── cloudrun/
│       │   ├── iam_bindings/
│       │   ├── monitoring/
│       │   ├── observability/
│       │   ├── pubsub/
│       │   └── service_accounts/
│       └── tests/              # Terraform native tests
├── bootstrap/gcp/              # Bootstrap resources
│   ├── github-actions-auth/    # Workload Identity Federation
│   ├── secrets/                # Secret Manager setup
│   └── terraform-state/        # GCS state bucket
├── .github/workflows/          # GitHub Actions CI/CD
├── scripts/                    # Utility scripts
└── docs/                       # Architecture documentation
```

## Quick Start

```bash
# Navigate to pattern
cd architectures/event-driven/gcp

# Copy and configure
cp terraform.tfvars.example terraform.tfvars
cp secrets.auto.tfvars.example secrets.auto.tfvars
cp backend.hcl.example backend.hcl
# Edit files with your values

# Initialize and deploy
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

## CI/CD

Automated deployment with GitHub Actions.

- **CI**: Format check, validation, TFLint, Trivy security scan, Terraform test
- **Deploy**: Change detection, environment-specific deployment, approval workflow
- **Auth**: GCP Workload Identity Federation (no service account keys)

## Prerequisites

- Terraform >= 1.13
- Google Cloud SDK
- GCP project with authentication (`gcloud auth application-default login`)
- Enable required GCP APIs (see each pattern's documentation)

## Development

```bash
# Format and validate
terraform fmt -recursive
terraform validate

# Run TFLint
tflint --init && tflint

# Run tests
terraform test -test-directory=tests

# Validate pattern (all checks)
./scripts/validate-tf.sh event-driven
```

## License

MIT License

## References

- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Google Cloud Architecture Center](https://cloud.google.com/architecture)
- [Documentation](docs/)
