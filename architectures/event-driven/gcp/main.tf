# Local variables for common tags and naming
locals {
  common_labels = {
    environment = var.environment
    managed_by  = "terraform"
    project     = var.project_name
  }

  resource_prefix = "${var.environment}-${var.project_name}"
}

# Step 0: Create Artifact Registry (no dependencies)
module "artifact_registry" {
  source = "./modules/artifact_registry"

  project_id   = var.project_id
  region       = var.region
  environment  = var.environment
  project_name = var.project_name
}

# Step 1: Create Service Accounts (no dependencies)
module "service_accounts" {
  source = "./modules/service_accounts"

  # Project Configuration
  project_id      = var.project_id
  environment     = var.environment
  resource_prefix = local.resource_prefix
}

# Step 2: Deploy Cloud Run Service (depends on service_accounts)
module "cloudrun" {
  source = "./modules/cloudrun"

  # Project Configuration
  project_id      = var.project_id
  region          = var.region
  environment     = var.environment
  resource_prefix = local.resource_prefix
  common_labels   = local.common_labels

  # Dependencies from service_accounts module
  service_account_email = module.service_accounts.cloud_run_service_account_email

  # Cloud Run Configuration
  container_image      = "asia-northeast1-docker.pkg.dev/${var.project_id}/cloudrun-images/event-handler:release"
  min_instances        = var.min_instances
  max_instances        = var.max_instances
  concurrency          = var.concurrency
  cpu_limit            = var.cpu_limit
  memory_limit         = var.memory_limit
  cpu_always_allocated = var.cpu_always_allocated
  startup_cpu_boost    = var.startup_cpu_boost
  request_timeout      = var.request_timeout
  log_level            = var.log_level
  additional_env_vars  = var.additional_env_vars
  enable_health_check  = var.enable_health_check
  health_check_path    = var.health_check_path

  # VPC Configuration
  vpc_connector_name = var.vpc_connector_name
  vpc_egress         = var.vpc_egress

  # Observability Configuration
  enable_cloud_trace            = var.enable_cloud_trace
  trace_sampling_rate           = var.trace_sampling_rate
  enable_error_reporting_metric = var.enable_error_reporting_metric
}

# Step 3: Create Pub/Sub Resources (depends on cloudrun and service_accounts)
module "pubsub" {
  source = "./modules/pubsub"

  # Project Configuration
  project_id      = var.project_id
  resource_prefix = local.resource_prefix
  common_labels   = local.common_labels

  # Dependencies from other modules
  push_endpoint              = module.cloudrun.service_uri
  oidc_service_account_email = module.service_accounts.pubsub_service_account_email

  # Pub/Sub Configuration
  topic_name                              = var.topic_name
  message_retention_duration              = var.message_retention_duration
  ack_deadline_seconds                    = var.ack_deadline_seconds
  retry_minimum_backoff                   = var.retry_minimum_backoff
  retry_maximum_backoff                   = var.retry_maximum_backoff
  max_delivery_attempts                   = var.max_delivery_attempts
  subscription_message_retention_duration = var.subscription_message_retention_duration
  enable_exactly_once_delivery            = var.enable_exactly_once_delivery
}

# Step 4: Configure IAM Bindings (depends on service_accounts, cloudrun, and pubsub)
module "iam_bindings" {
  source = "./modules/iam_bindings"

  # Project Configuration
  project_id = var.project_id

  # Dependencies from service_accounts module
  cloud_run_service_account_email = module.service_accounts.cloud_run_service_account_email
  pubsub_service_account_email    = module.service_accounts.pubsub_service_account_email

  # Dependencies from cloudrun module
  cloud_run_service_name     = module.cloudrun.service_name
  cloud_run_service_location = module.cloudrun.location

  # Dependencies from pubsub module
  dead_letter_topic_name  = module.pubsub.dead_letter_topic_name
  event_subscription_name = module.pubsub.subscription_name

  # IAM Configuration
  enable_cloud_trace            = var.enable_cloud_trace
  enable_error_reporting_metric = var.enable_error_reporting_metric
  enable_custom_metrics         = var.enable_custom_metrics
  cloud_run_additional_roles    = var.cloud_run_additional_roles
}

# Step 5: Configure Monitoring (depends on cloudrun and pubsub)
module "monitoring" {
  source = "./modules/monitoring"

  # Project Configuration
  project_id      = var.project_id
  environment     = var.environment
  project_name    = var.project_name
  resource_prefix = local.resource_prefix

  # Dependencies from other modules
  cloud_run_service_name        = module.cloudrun.service_name
  dead_letter_subscription_name = module.pubsub.dead_letter_subscription_name
  event_subscription_name       = module.pubsub.subscription_name

  # Monitoring Configuration
  enable_monitoring                    = var.enable_monitoring
  notification_channels                = var.notification_channels
  dlq_alert_threshold                  = var.dlq_alert_threshold
  error_rate_threshold                 = var.error_rate_threshold
  oldest_unacked_message_age_threshold = var.oldest_unacked_message_age_threshold
  max_delivery_attempts                = var.max_delivery_attempts
  enable_custom_metrics                = var.enable_custom_metrics
}

# Step 6: Configure Observability (depends on cloudrun and pubsub)
module "observability" {
  source = "./modules/observability"

  # Project Configuration
  project_id      = var.project_id
  environment     = var.environment
  project_name    = var.project_name
  resource_prefix = local.resource_prefix

  # Dependencies from other modules
  cloud_run_service_name        = module.cloudrun.service_name
  event_topic_name              = module.pubsub.topic_name
  event_subscription_name       = module.pubsub.subscription_name
  dead_letter_subscription_name = module.pubsub.dead_letter_subscription_name

  # Observability Configuration
  enable_observability_dashboard = var.enable_observability_dashboard
  enable_error_reporting_metric  = var.enable_error_reporting_metric
  error_reporting_threshold      = var.error_reporting_threshold
  enable_cloud_trace             = var.enable_cloud_trace
  enable_error_log_sink          = var.enable_error_log_sink
  error_log_dataset_id           = var.error_log_dataset_id
  enable_monitoring              = var.enable_monitoring
  notification_channels          = var.notification_channels
  dlq_alert_threshold            = var.dlq_alert_threshold
}
