# Alert Policy: High Pod Restart Rate
resource "google_monitoring_alert_policy" "pod_restart" {
  count = var.enable_monitoring && length(var.notification_channels) > 0 ? 1 : 0

  display_name = "${local.resource_prefix} - High Pod Restart Rate"
  project      = var.project_id

  conditions {
    display_name = "Pod restart rate exceeds threshold"

    condition_threshold {
      filter          = <<-EOT
        resource.type = "k8s_pod"
        AND resource.labels.cluster_name = "${google_container_cluster.primary.name}"
        AND metric.type = "kubernetes.io/container/restart_count"
      EOT
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.pod_restart_threshold

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = var.notification_channels

  alert_strategy {
    auto_close = "86400s"
  }

  combiner = "OR"

  documentation {
    content   = "Pod restart rate has exceeded ${var.pod_restart_threshold} restarts in 5 minutes. Check pod logs and events."
    mime_type = "text/markdown"
  }
}

# Alert Policy: High Node CPU Utilization
resource "google_monitoring_alert_policy" "node_cpu" {
  count = var.enable_monitoring && length(var.notification_channels) > 0 ? 1 : 0

  display_name = "${local.resource_prefix} - High Node CPU Utilization"
  project      = var.project_id

  conditions {
    display_name = "Node CPU utilization exceeds threshold"

    condition_threshold {
      filter          = <<-EOT
        resource.type = "k8s_node"
        AND resource.labels.cluster_name = "${google_container_cluster.primary.name}"
        AND metric.type = "kubernetes.io/node/cpu/allocatable_utilization"
      EOT
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.node_cpu_threshold / 100

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.notification_channels

  alert_strategy {
    auto_close = "86400s"
  }

  combiner = "OR"

  documentation {
    content   = "Node CPU utilization has exceeded ${var.node_cpu_threshold}% for 5 minutes. Consider scaling or optimizing workloads."
    mime_type = "text/markdown"
  }
}

# Alert Policy: High Node Memory Utilization
resource "google_monitoring_alert_policy" "node_memory" {
  count = var.enable_monitoring && length(var.notification_channels) > 0 ? 1 : 0

  display_name = "${local.resource_prefix} - High Node Memory Utilization"
  project      = var.project_id

  conditions {
    display_name = "Node memory utilization exceeds threshold"

    condition_threshold {
      filter          = <<-EOT
        resource.type = "k8s_node"
        AND resource.labels.cluster_name = "${google_container_cluster.primary.name}"
        AND metric.type = "kubernetes.io/node/memory/allocatable_utilization"
      EOT
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.node_memory_threshold / 100

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.notification_channels

  alert_strategy {
    auto_close = "86400s"
  }

  combiner = "OR"

  documentation {
    content   = "Node memory utilization has exceeded ${var.node_memory_threshold}% for 5 minutes. Consider scaling or optimizing workloads."
    mime_type = "text/markdown"
  }
}

# Alert Policy: Pods in Pending State
resource "google_monitoring_alert_policy" "pod_pending" {
  count = var.enable_monitoring && length(var.notification_channels) > 0 ? 1 : 0

  display_name = "${local.resource_prefix} - Pods Stuck in Pending State"
  project      = var.project_id

  conditions {
    display_name = "Pods pending exceeds threshold"

    condition_threshold {
      filter          = <<-EOT
        resource.type = "k8s_pod"
        AND resource.labels.cluster_name = "${google_container_cluster.primary.name}"
        AND metric.type = "kubernetes.io/pod/status/phase"
        AND metric.labels.phase = "Pending"
      EOT
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.pod_pending_threshold

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_MEAN"
        cross_series_reducer = "REDUCE_COUNT"
      }
    }
  }

  notification_channels = var.notification_channels

  alert_strategy {
    auto_close = "86400s"
  }

  combiner = "OR"

  documentation {
    content   = "More than ${var.pod_pending_threshold} pods are stuck in Pending state for 5 minutes. Check for resource constraints or scheduling issues."
    mime_type = "text/markdown"
  }
}

# Uptime Check for Ingress
resource "google_monitoring_uptime_check_config" "ingress_health" {
  count = var.enable_monitoring && var.enable_ingress ? 1 : 0

  display_name = "${local.resource_prefix} - Ingress Health Check"
  project      = var.project_id
  timeout      = "10s"
  period       = "60s"

  http_check {
    path           = "/health"
    port           = 443
    use_ssl        = true
    validate_ssl   = true
    request_method = "GET"
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = google_compute_global_address.ingress[0].address
    }
  }

  content_matchers {
    content = "ok"
    matcher = "CONTAINS_STRING"
  }
}

# Alert Policy for Uptime Check
resource "google_monitoring_alert_policy" "uptime_check" {
  count = var.enable_monitoring && var.enable_ingress && length(var.notification_channels) > 0 ? 1 : 0

  display_name = "${local.resource_prefix} - Ingress Uptime Check Failed"
  project      = var.project_id

  conditions {
    display_name = "Uptime check failed"

    condition_threshold {
      filter          = <<-EOT
        resource.type = "uptime_url"
        AND metric.type = "monitoring.googleapis.com/uptime_check/check_passed"
        AND metric.labels.check_id = "${google_monitoring_uptime_check_config.ingress_health[0].uptime_check_id}"
      EOT
      duration        = "300s"
      comparison      = "COMPARISON_LT"
      threshold_value = 1

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_FRACTION_TRUE"
      }
    }
  }

  notification_channels = var.notification_channels

  alert_strategy {
    auto_close = "86400s"
  }

  combiner = "OR"

  documentation {
    content   = "Uptime check has failed for the Ingress endpoint. Check the application health and load balancer status."
    mime_type = "text/markdown"
  }
}
