# Alert Policy Outputs
output "alert_policy_ids" {
  description = "List of alert policy IDs"
  value = concat(
    var.enable_monitoring ? [
      google_monitoring_alert_policy.dead_letter_messages[0].id,
      google_monitoring_alert_policy.high_error_rate[0].id,
      google_monitoring_alert_policy.old_unacked_messages[0].id
    ] : [],
  )
}
