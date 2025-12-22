# =============================================
# Workflows
# =============================================
# Orchestrates batch processing workflow
# Handles error handling, retries, and job execution
# =============================================

resource "google_workflows_workflow" "batch_workflow" {
  name            = "${local.service_prefix}-workflow"
  description     = "Batch processing workflow orchestration"
  region          = var.region
  project         = var.project_id
  service_account = google_service_account.workflow_sa.email

  source_contents = templatefile("${path.module}/workflow.yaml", {
    project_id = var.project_id
    region     = var.region
    job_name   = google_cloud_run_v2_job.batch_job.name
  })

  labels = local.common_labels

  depends_on = [
    google_project_service.required_apis,
    google_cloud_run_v2_job.batch_job
  ]
}
