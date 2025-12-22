# Terraform GCP Observable Architecture Patterns

Production-ready GCP architecture patterns with Terraform and comprehensive observability

## Features

- **Environment Isolation**: Completely separated state management for dev/prod
- **Modular Design**: Reusable Terraform modules
- **Production-Ready**: Security, monitoring, and alerting built-in
- **GitOps Support**: Automated deployment with GitHub Actions

## Architecture Patterns

### 1. Event-Driven Architecture
Event-driven system using Pub/Sub + Cloud Run

- Push-based message delivery, Dead Letter Queue, automatic retry
- Details: [patterns/event-driven/gcp/](architectures/event-driven/gcp/)

### 2. Microservices on GKE Autopilot
Microservices architecture with GKE Autopilot + Ingress

- Fully managed Kubernetes, Workload Identity, Managed SSL
- Details: [patterns/microservices-gke/gcp/](architectures/microservices-gke/gcp/)

### 3. Workflow Batch Pattern
Batch processing with Cloud Scheduler + Workflows + Cloud Run Job

- Scheduled execution, job orchestration, error handling
- Details: [patterns/workflow-batch/gcp/](architectures/workflow-batch/gcp/)

## Project Structure

```
tf-observable-architecture-patterns/
├── patterns/                    # Architecture patterns
│   ├── event-driven/gcp/
│   │   ├── modules/            # Reusable modules
│   │   └── environments/       # dev/prod configurations
│   ├── microservices-gke/
│   │   ├── gcp/               # Terraform configuration
│   │   └── k8s/               # Kubernetes manifests
│   └── workflow-batch/gcp/
│       ├── modules/
│       └── environments/
├── .github/workflows/          # GitHub Actions CI/CD
└── docs/                       # Architecture documentation
```

## Quick Start

```bash
# Choose a pattern (event-driven/microservices-gke/workflow-batch)
cd architectures/event-driven/gcp/environments/dev

# Prepare configuration
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and set your project_id

# Deploy
terraform init
terraform plan
terraform apply
```

## GitOps (CI/CD)

Automated deployment with GitHub Actions

- **CI**: terraform fmt/validate/tflint, security scan (Trivy)
- **Deploy**: Change detection, environment-specific deployment, approval workflow
- **Auth**: GCP Workload Identity Federation

Details: [docs/gitops-setup.md](docs/gitops-setup.md)

## Prerequisites

- Terraform >= 1.13
- Google Cloud SDK
- GCP project + authentication (`gcloud auth application-default login`)
- Enable required GCP APIs (see each pattern's README)

## License

MIT License

## References

- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Google Cloud Architecture Center](https://cloud.google.com/architecture)
- [Detailed design documents](docs/)
