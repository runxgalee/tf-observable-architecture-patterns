# Pub/Sub Module Tests
# Tests Pub/Sub topic and subscription naming and configuration

mock_provider "google" {
  override_data {
    target = data.google_project.project
    values = {
      project_id = "test-project"
      number     = "123456789012"
    }
  }
}

# Common variables for all tests
variables {
  project_id      = "test-project"
  region          = "asia-northeast1"
  environment     = "dev"
  project_name    = "events"
  container_image = "gcr.io/test/image:latest"
  topic_name      = "events"
}

# =============================================================================
# Pub/Sub Topic Naming Tests
# =============================================================================

run "pubsub_topic_naming" {
  command = plan

  assert {
    condition     = output.topic_name == "dev-events-events"
    error_message = "Topic name should be '{env}-{project_name}-{topic_name}'"
  }

  assert {
    condition     = output.dead_letter_topic_name == "dev-events-events-dead-letter"
    error_message = "Dead letter topic name should have '-dead-letter' suffix"
  }
}

run "pubsub_subscription_naming" {
  command = plan

  assert {
    condition     = output.subscription_name == "dev-events-events-subscription"
    error_message = "Subscription name should have '-subscription' suffix"
  }

  assert {
    condition     = output.dead_letter_subscription_name == "dev-events-events-dead-letter-subscription"
    error_message = "Dead letter subscription name should have '-dead-letter-subscription' suffix"
  }
}

# =============================================================================
# Custom Topic Name Tests
# =============================================================================

run "pubsub_custom_topic_name" {
  command = plan

  variables {
    topic_name = "orders"
  }

  assert {
    condition     = output.topic_name == "dev-events-orders"
    error_message = "Topic name should use custom topic_name variable"
  }

  assert {
    condition     = output.dead_letter_topic_name == "dev-events-orders-dead-letter"
    error_message = "Dead letter topic should use custom topic_name variable"
  }
}

run "pubsub_prod_environment" {
  command = plan

  variables {
    environment  = "prod"
    project_name = "myapp"
    topic_name   = "notifications"
  }

  assert {
    condition     = output.topic_name == "prod-myapp-notifications"
    error_message = "Topic naming should work for prod environment"
  }
}

# =============================================================================
# Exactly Once Delivery Tests
# =============================================================================

run "pubsub_exactly_once_disabled" {
  command = plan

  variables {
    enable_exactly_once_delivery = false
  }

  # Exactly once delivery should be disabled
}

run "pubsub_exactly_once_enabled" {
  command = plan

  variables {
    enable_exactly_once_delivery = true
  }

  # Exactly once delivery should be enabled
}
