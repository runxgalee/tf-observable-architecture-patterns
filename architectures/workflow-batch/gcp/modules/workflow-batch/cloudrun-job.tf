# =============================================
# Cloud Run Job
# =============================================
# Containerized batch processing job
# =============================================

resource "google_cloud_run_v2_job" "batch_job" {
  name     = "${local.service_prefix}-job"
  location = var.region
  project  = var.project_id

  template {
    task_count = var.job_task_count

    template {
      timeout         = var.job_timeout
      max_retries     = var.job_max_retries
      service_account = google_service_account.job_sa.email

      containers {
        image = var.job_image

        resources {
          limits = {
            cpu    = var.job_cpu
            memory = var.job_memory
          }
        }

        # Environment variables
        dynamic "env" {
          for_each = merge(
            var.job_env_vars,
            {
              ENVIRONMENT = var.environment
              PROJECT_ID  = var.project_id
              REGION      = var.region
            }
          )
          content {
            name  = env.key
            value = env.value
          }
        }
      }

      # VPC Access (optional, uncomment if needed)
      # vpc_access {
      #   connector = var.vpc_connector
      #   egress    = "PRIVATE_RANGES_ONLY"
      # }
    }
  }

  labels = local.common_labels

  depends_on = [
    google_project_service.required_apis
  ]

  lifecycle {
    ignore_changes = [
      launch_stage,
    ]
  }
}
