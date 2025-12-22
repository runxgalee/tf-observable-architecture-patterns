# =============================================
# Monitoring & Alerting
# =============================================
# Monitoring configuration for:
# - Workflow execution failures
# - Job execution failures
# - Scheduler job failures
# =============================================

# Notification Channel (if email is provided)
resource "google_monitoring_notification_channel" "email" {
  count        = var.enable_monitoring && var.alert_email != "" ? 1 : 0
  display_name = "${local.service_prefix} Alert Email"
  type         = "email"
  project      = var.project_id

  labels = {
    email_address = var.alert_email
  }
}

# =============================================
# Alert Policy: Workflow Execution Failures
# =============================================

resource "google_monitoring_alert_policy" "workflow_failures" {
  count        = var.enable_monitoring ? 1 : 0
  display_name = "${local.service_prefix} - Workflow Execution Failures"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Workflow execution failed"

    condition_matched_log {
      filter = <<-EOT
        resource.type="workflows.googleapis.com/Workflow"
        resource.labels.workflow_id="${google_workflows_workflow.batch_workflow.name}"
        resource.labels.location="${var.region}"
        severity=ERROR
        jsonPayload.state="FAILED"
      EOT
    }
  }

  alert_strategy {
    auto_close = "1800s"
  }

  notification_channels = var.alert_email != "" ? [google_monitoring_notification_channel.email[0].id] : []

  documentation {
    content   = <<-EOT
      ## Workflow Execution Failed

      The batch workflow execution has failed.

      **Actions:**
      1. Check workflow execution logs:
         ```
         gcloud workflows executions list ${google_workflows_workflow.batch_workflow.name} --location=${var.region}
         ```
      2. View detailed execution logs in Cloud Logging
      3. Check if the Cloud Run Job failed
      4. Review workflow definition for errors

      **Common causes:**
      - Cloud Run Job execution failure
      - Permission issues
      - Timeout exceeded
      - Resource quota exceeded
    EOT
    mime_type = "text/markdown"
  }
}

# =============================================
# Alert Policy: Cloud Run Job Failures
# =============================================

resource "google_monitoring_alert_policy" "job_failures" {
  count        = var.enable_monitoring ? 1 : 0
  display_name = "${local.service_prefix} - Job Execution Failures"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Cloud Run Job failed multiple times"

    condition_threshold {
      filter          = <<-EOT
        resource.type="cloud_run_job"
        resource.labels.job_name="${google_cloud_run_v2_job.batch_job.name}"
        resource.labels.location="${var.region}"
        metric.type="run.googleapis.com/job/completed_execution_count"
        metric.labels.result="failed"
      EOT
      duration        = "0s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.job_failure_threshold

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_DELTA"
      }
    }
  }

  alert_strategy {
    auto_close = "1800s"
  }

  notification_channels = var.alert_email != "" ? [google_monitoring_notification_channel.email[0].id] : []

  documentation {
    content   = <<-EOT
      ## Cloud Run Job Failed

      The Cloud Run Job has failed ${var.job_failure_threshold} or more times.

      **Actions:**
      1. Check job execution logs:
         ```
         gcloud logging read 'resource.type=cloud_run_job AND resource.labels.job_name=${google_cloud_run_v2_job.batch_job.name}' --limit 50
         ```
      2. Review error messages in the logs
      3. Check container image and configuration
      4. Verify service account permissions

      **Common causes:**
      - Application errors in the container
      - Insufficient memory or CPU
      - Permission issues
      - External service unavailable
    EOT
    mime_type = "text/markdown"
  }
}

# =============================================
# Alert Policy: Scheduler Job Failures
# =============================================

resource "google_monitoring_alert_policy" "scheduler_failures" {
  count        = var.enable_monitoring ? 1 : 0
  display_name = "${local.service_prefix} - Scheduler Job Failures"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Scheduler failed to trigger workflow"

    condition_matched_log {
      filter = <<-EOT
        resource.type="cloud_scheduler_job"
        resource.labels.job_id="${google_cloud_scheduler_job.workflow_trigger.name}"
        resource.labels.location="${var.region}"
        severity>=ERROR
      EOT
    }
  }

  alert_strategy {
    auto_close = "1800s"
  }

  notification_channels = var.alert_email != "" ? [google_monitoring_notification_channel.email[0].id] : []

  documentation {
    content   = <<-EOT
      ## Scheduler Job Failed

      Cloud Scheduler failed to trigger the workflow.

      **Actions:**
      1. Check scheduler job status:
         ```
         gcloud scheduler jobs describe ${google_cloud_scheduler_job.workflow_trigger.name} --location=${var.region}
         ```
      2. Verify IAM permissions for scheduler service account
      3. Check if Workflows API is enabled
      4. Review scheduler configuration

      **Common causes:**
      - Permission issues
      - Workflow not found
      - API quota exceeded
      - Network connectivity issues
    EOT
    mime_type = "text/markdown"
  }
}

# =============================================
# Dashboard (Optional)
# =============================================

resource "google_monitoring_dashboard" "workflow_batch" {
  count = var.enable_monitoring ? 1 : 0
  dashboard_json = jsonencode({
    displayName = "${local.service_prefix} Dashboard"
    mosaicLayout = {
      columns = 12
      tiles = [
        {
          width  = 6
          height = 4
          widget = {
            title = "Workflow Executions"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"workflows.googleapis.com/Workflow\" resource.labels.workflow_id=\"${google_workflows_workflow.batch_workflow.name}\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_RATE"
                    }
                  }
                }
              }]
            }
          }
        },
        {
          xPos   = 6
          width  = 6
          height = 4
          widget = {
            title = "Job Execution Status"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_run_job\" resource.labels.job_name=\"${google_cloud_run_v2_job.batch_job.name}\" metric.type=\"run.googleapis.com/job/completed_execution_count\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_DELTA"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields      = ["metric.label.result"]
                    }
                  }
                }
              }]
            }
          }
        }
      ]
    }
  })
}
