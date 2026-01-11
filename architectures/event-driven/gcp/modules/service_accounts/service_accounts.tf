# Service Account for Cloud Run
resource "google_service_account" "cloud_run_sa" {
  account_id   = "${local.resource_prefix}-event-processor"
  display_name = "${var.environment} Event Processor Service Account"
  description  = "Service account for Cloud Run event processor in ${var.environment}"
  project      = var.project_id
}

# Service Account for Pub/Sub to invoke Cloud Run
resource "google_service_account" "pubsub_sa" {
  account_id   = "${local.resource_prefix}-pubsub-invoker"
  display_name = "${var.environment} Pub/Sub Invoker Service Account"
  description  = "Service account for Pub/Sub to invoke Cloud Run in ${var.environment}"
  project      = var.project_id
}
