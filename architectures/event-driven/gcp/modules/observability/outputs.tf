# Observability Outputs
output "dashboard_id" {
  description = "ID of the monitoring dashboard"
  value       = var.enable_observability_dashboard ? google_monitoring_dashboard.event_driven_dashboard[0].id : null
}

output "dashboard_url" {
  description = "URL to view the monitoring dashboard in Cloud Console"
  value       = var.enable_observability_dashboard ? "https://console.cloud.google.com/monitoring/dashboards/custom/${google_monitoring_dashboard.event_driven_dashboard[0].id}?project=${var.project_id}" : null
}

output "error_reporting_url" {
  description = "URL to view Error Reporting in Cloud Console"
  value       = "https://console.cloud.google.com/errors?project=${var.project_id}"
}

output "cloud_trace_url" {
  description = "URL to view Cloud Trace in Cloud Console"
  value       = var.enable_cloud_trace ? "https://console.cloud.google.com/traces/list?project=${var.project_id}" : null
}

output "cloud_logging_url" {
  description = "URL to view Cloud Logging in Cloud Console"
  value       = "https://console.cloud.google.com/logs/query?project=${var.project_id}&query=resource.type%3D%22cloud_run_revision%22%0Aresource.labels.service_name%3D%22${var.cloud_run_service_name}%22"
}

output "observability_enabled" {
  description = "Map of enabled observability features"
  value = {
    dashboard       = var.enable_observability_dashboard
    error_reporting = var.enable_error_reporting_metric
    cloud_trace     = var.enable_cloud_trace
    log_sink        = var.enable_error_log_sink
  }
}
