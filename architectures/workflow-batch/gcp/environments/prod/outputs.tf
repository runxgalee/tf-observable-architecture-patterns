# =============================================
# Outputs
# =============================================

# Cloud Scheduler
output "scheduler_id" {
  description = "The ID of the Cloud Scheduler job"
  value       = module.workflow_batch.scheduler_id
}

output "scheduler_name" {
  description = "The name of the Cloud Scheduler job"
  value       = module.workflow_batch.scheduler_name
}

# Workflows
output "workflow_id" {
  description = "The ID of the Workflow"
  value       = module.workflow_batch.workflow_id
}

output "workflow_name" {
  description = "The name of the Workflow"
  value       = module.workflow_batch.workflow_name
}

# Cloud Run Job
output "job_name" {
  description = "The name of the Cloud Run Job"
  value       = module.workflow_batch.job_name
}

output "job_id" {
  description = "The ID of the Cloud Run Job"
  value       = module.workflow_batch.job_id
}

# Service Accounts
output "workflow_service_account" {
  description = "Service account email for Workflows"
  value       = module.workflow_batch.workflow_service_account
}

output "job_service_account" {
  description = "Service account email for Cloud Run Job"
  value       = module.workflow_batch.job_service_account
}

# Useful Commands
output "trigger_workflow_command" {
  description = "Command to manually trigger the workflow"
  value       = module.workflow_batch.trigger_workflow_command
}

output "trigger_job_command" {
  description = "Command to manually trigger the job"
  value       = module.workflow_batch.trigger_job_command
}

output "list_executions_command" {
  description = "Command to list workflow executions"
  value       = module.workflow_batch.list_executions_command
}

output "view_logs_command" {
  description = "Command to view job logs"
  value       = module.workflow_batch.view_logs_command
}
