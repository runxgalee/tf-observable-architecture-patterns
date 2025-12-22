# =============================================
# Workflow Batch Pattern Module
# =============================================
# This module implements a workflow-based batch processing pattern using:
# - Cloud Scheduler: Scheduled job triggering
# - Workflows: Orchestration and error handling
# - Cloud Run Job: Containerized batch processing
# =============================================

locals {
  common_labels = merge(
    {
      environment = var.environment
      managed_by  = "terraform"
      pattern     = "workflow-batch"
    },
    var.labels
  )

  service_prefix = "${var.service_name}-${var.environment}"
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "cloudscheduler.googleapis.com",
    "workflows.googleapis.com",
    "run.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ])

  project = var.project_id
  service = each.key

  disable_on_destroy = false
}
