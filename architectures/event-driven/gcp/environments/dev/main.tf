# Event-Driven Architecture - Development Environment

module "event_driven" {
  source = "../../modules/event-driven"

  # Project Configuration
  project_id   = var.project_id
  region       = var.region
  environment  = "dev"
  project_name = var.project_name

  # Pub/Sub Configuration
  topic_name                              = var.topic_name
  message_retention_duration              = var.message_retention_duration
  ack_deadline_seconds                    = var.ack_deadline_seconds
  retry_minimum_backoff                   = var.retry_minimum_backoff
  retry_maximum_backoff                   = var.retry_maximum_backoff
  max_delivery_attempts                   = var.max_delivery_attempts
  subscription_message_retention_duration = var.subscription_message_retention_duration
  enable_exactly_once_delivery            = var.enable_exactly_once_delivery

  # Cloud Run Configuration
  container_image      = var.container_image
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

  # IAM Configuration
  cloud_run_additional_roles = var.cloud_run_additional_roles

  # Monitoring Configuration
  enable_monitoring                    = var.enable_monitoring
  notification_channels                = var.notification_channels
  dlq_alert_threshold                  = var.dlq_alert_threshold
  error_rate_threshold                 = var.error_rate_threshold
  oldest_unacked_message_age_threshold = var.oldest_unacked_message_age_threshold
  enable_custom_metrics                = var.enable_custom_metrics
}
