# Cloud Scheduler outputs
output "scheduler_id" {
  description = "The ID of the Cloud Scheduler job"
  value       = google_cloud_scheduler_job.workflow_trigger.id
}

output "scheduler_name" {
  description = "The name of the Cloud Scheduler job"
  value       = google_cloud_scheduler_job.workflow_trigger.name
}

# Workflows outputs
output "workflow_id" {
  description = "The ID of the Workflow"
  value       = google_workflows_workflow.batch_workflow.id
}

output "workflow_name" {
  description = "The name of the Workflow"
  value       = google_workflows_workflow.batch_workflow.name
}

# Cloud Run Job outputs
output "job_name" {
  description = "The name of the Cloud Run Job"
  value       = google_cloud_run_v2_job.batch_job.name
}

output "job_id" {
  description = "The ID of the Cloud Run Job"
  value       = google_cloud_run_v2_job.batch_job.id
}

output "job_location" {
  description = "The location of the Cloud Run Job"
  value       = google_cloud_run_v2_job.batch_job.location
}

# Service Account outputs
output "workflow_service_account" {
  description = "Service account email for Workflows"
  value       = google_service_account.workflow_sa.email
}

output "job_service_account" {
  description = "Service account email for Cloud Run Job"
  value       = google_service_account.job_sa.email
}

# Useful commands
output "trigger_workflow_command" {
  description = "Command to manually trigger the workflow"
  value       = "gcloud workflows execute ${google_workflows_workflow.batch_workflow.name} --location=${var.region}"
}

output "trigger_job_command" {
  description = "Command to manually trigger the job"
  value       = "gcloud run jobs execute ${google_cloud_run_v2_job.batch_job.name} --region=${var.region}"
}

output "list_executions_command" {
  description = "Command to list workflow executions"
  value       = "gcloud workflows executions list ${google_workflows_workflow.batch_workflow.name} --location=${var.region}"
}

output "view_logs_command" {
  description = "Command to view job logs"
  value       = "gcloud logging read 'resource.type=cloud_run_job AND resource.labels.job_name=${google_cloud_run_v2_job.batch_job.name}' --limit 50 --format json"
}
