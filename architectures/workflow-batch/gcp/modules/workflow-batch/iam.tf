# =============================================
# IAM Resources
# =============================================
# Service accounts and IAM bindings for:
# - Cloud Scheduler
# - Workflows
# - Cloud Run Job
# =============================================

# Service Account for Cloud Scheduler
resource "google_service_account" "scheduler_sa" {
  account_id   = "${local.service_prefix}-scheduler"
  display_name = "Service Account for Cloud Scheduler (${var.environment})"
  description  = "Used by Cloud Scheduler to trigger Workflows"
  project      = var.project_id
}

# Service Account for Workflows
resource "google_service_account" "workflow_sa" {
  account_id   = "${local.service_prefix}-workflow"
  display_name = "Service Account for Workflows (${var.environment})"
  description  = "Used by Workflows to execute Cloud Run Jobs"
  project      = var.project_id
}

# Service Account for Cloud Run Job
resource "google_service_account" "job_sa" {
  account_id   = "${local.service_prefix}-job"
  display_name = "Service Account for Cloud Run Job (${var.environment})"
  description  = "Used by Cloud Run Job for batch processing"
  project      = var.project_id
}

# =============================================
# Cloud Scheduler IAM
# =============================================

# Allow Scheduler SA to invoke Workflows
resource "google_project_iam_member" "scheduler_workflows_invoker" {
  project = var.project_id
  role    = "roles/workflows.invoker"
  member  = "serviceAccount:${google_service_account.scheduler_sa.email}"
}

# =============================================
# Workflows IAM
# =============================================

# Allow Workflow SA to run Cloud Run Jobs
resource "google_project_iam_member" "workflow_run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.workflow_sa.email}"
}

# Allow Workflow SA to get job execution status
resource "google_project_iam_member" "workflow_run_viewer" {
  project = var.project_id
  role    = "roles/run.viewer"
  member  = "serviceAccount:${google_service_account.workflow_sa.email}"
}

# Allow Workflow SA to write logs
resource "google_project_iam_member" "workflow_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.workflow_sa.email}"
}

# =============================================
# Cloud Run Job IAM
# =============================================

# Allow Job SA to write logs
resource "google_project_iam_member" "job_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.job_sa.email}"
}

# Allow Job SA to write metrics (optional)
resource "google_project_iam_member" "job_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.job_sa.email}"
}

# Add additional permissions for the job as needed
# For example, if the job needs to access Cloud Storage:
# resource "google_project_iam_member" "job_storage_viewer" {
#   project = var.project_id
#   role    = "roles/storage.objectViewer"
#   member  = "serviceAccount:${google_service_account.job_sa.email}"
# }
