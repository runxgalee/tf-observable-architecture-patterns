# =============================================
# Development Environment Configuration
# =============================================

module "workflow_batch" {
  source = "../../modules/workflow-batch"

  # Basic Configuration
  project_id  = var.project_id
  region      = var.region
  environment = "dev"

  # Service Configuration
  service_name = var.service_name

  # Cloud Scheduler Configuration
  scheduler_schedule  = var.scheduler_schedule
  scheduler_time_zone = var.scheduler_time_zone

  # Cloud Run Job Configuration
  job_task_count  = var.job_task_count
  job_max_retries = var.job_max_retries
  job_timeout     = var.job_timeout
  job_cpu         = var.job_cpu
  job_memory      = var.job_memory
  job_image       = var.job_image
  job_env_vars    = var.job_env_vars

  # Monitoring Configuration
  enable_monitoring     = var.enable_monitoring
  alert_email           = var.alert_email
  job_failure_threshold = var.job_failure_threshold

  # Labels
  labels = var.labels
}
