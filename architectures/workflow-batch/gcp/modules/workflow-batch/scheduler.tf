# =============================================
# Cloud Scheduler
# =============================================
# Triggers the workflow on a scheduled basis
# =============================================

resource "google_cloud_scheduler_job" "workflow_trigger" {
  name        = "${local.service_prefix}-trigger"
  description = var.scheduler_description
  schedule    = var.scheduler_schedule
  time_zone   = var.scheduler_time_zone
  region      = var.region
  project     = var.project_id

  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.batch_workflow.id}/executions"

    oauth_token {
      service_account_email = google_service_account.scheduler_sa.email
    }
  }

  retry_config {
    retry_count          = 3
    min_backoff_duration = "5s"
    max_backoff_duration = "3600s"
    max_retry_duration   = "0s"
    max_doublings        = 5
  }

  depends_on = [
    google_project_service.required_apis,
    google_workflows_workflow.batch_workflow
  ]
}
