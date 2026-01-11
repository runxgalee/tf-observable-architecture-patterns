# Pub/Sub Topic Outputs
output "topic_name" {
  description = "Name of the Pub/Sub topic"
  value       = google_pubsub_topic.event_topic.name
}

output "topic_id" {
  description = "ID of the Pub/Sub topic"
  value       = google_pubsub_topic.event_topic.id
}

output "dead_letter_topic_name" {
  description = "Name of the dead letter topic"
  value       = google_pubsub_topic.dead_letter_topic.name
}

output "dead_letter_topic_id" {
  description = "ID of the dead letter topic"
  value       = google_pubsub_topic.dead_letter_topic.id
}

# Pub/Sub Subscription Outputs
output "subscription_name" {
  description = "Name of the Pub/Sub subscription"
  value       = google_pubsub_subscription.event_subscription.name
}

output "subscription_id" {
  description = "ID of the Pub/Sub subscription"
  value       = google_pubsub_subscription.event_subscription.id
}

output "dead_letter_subscription_name" {
  description = "Name of the dead letter subscription"
  value       = google_pubsub_subscription.dead_letter_subscription.name
}
