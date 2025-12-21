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

# Grant Cloud Run Invoker role to Pub/Sub SA
resource "google_cloud_run_v2_service_iam_member" "pubsub_sa_invoker" {
  name     = google_cloud_run_v2_service.event_processor.name
  location = google_cloud_run_v2_service.event_processor.location
  project  = var.project_id
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.pubsub_sa.email}"
}

# Grant Cloud Run Invoker role to Google-managed Pub/Sub SA
# This is required for Pub/Sub push subscriptions
resource "google_cloud_run_v2_service_iam_member" "pubsub_invoker" {
  name     = google_cloud_run_v2_service.event_processor.name
  location = google_cloud_run_v2_service.event_processor.location
  project  = var.project_id
  role     = "roles/run.invoker"
  member   = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

# Grant Pub/Sub SA permission to publish to dead letter topic
resource "google_pubsub_topic_iam_member" "dead_letter_publisher" {
  topic   = google_pubsub_topic.dead_letter_topic.name
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

# Grant Pub/Sub SA permission to subscribe to main subscription
resource "google_pubsub_subscription_iam_member" "dead_letter_subscriber" {
  subscription = google_pubsub_subscription.event_subscription.name
  project      = var.project_id
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

# Grant Cloud Trace Agent role to Cloud Run SA for distributed tracing
resource "google_project_iam_member" "cloud_run_trace_agent" {
  count = var.enable_cloud_trace ? 1 : 0

  project = var.project_id
  role    = "roles/cloudtrace.agent"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Grant Error Reporting Writer role to Cloud Run SA
resource "google_project_iam_member" "cloud_run_error_writer" {
  count = var.enable_error_reporting_metric ? 1 : 0

  project = var.project_id
  role    = "roles/errorreporting.writer"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Grant Monitoring Metric Writer role for custom metrics
resource "google_project_iam_member" "cloud_run_metric_writer" {
  count = var.enable_custom_metrics || var.enable_error_reporting_metric ? 1 : 0

  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Additional IAM roles for Cloud Run SA (if specified)
resource "google_project_iam_member" "cloud_run_additional_roles" {
  for_each = toset(var.cloud_run_additional_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}
