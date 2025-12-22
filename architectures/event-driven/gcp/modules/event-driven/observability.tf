# Observability Configuration
# This file contains Cloud Trace, Error Reporting, and Monitoring Dashboard configurations

# Cloud Monitoring Dashboard
resource "google_monitoring_dashboard" "event_driven_dashboard" {
  count = var.enable_observability_dashboard ? 1 : 0

  dashboard_json = jsonencode({
    displayName = "${var.environment} - ${var.project_name} - Event-Driven Architecture"

    mosaicLayout = {
      columns = 12

      tiles = [
        # Pub/Sub Message Rate
        {
          width  = 6
          height = 4
          widget = {
            title = "Pub/Sub - Message Publish Rate"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"pubsub_topic\" AND resource.labels.topic_id=\"${google_pubsub_topic.event_topic.name}\" AND metric.type=\"pubsub.googleapis.com/topic/send_request_count\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields      = ["resource.topic_id"]
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = {
                label = "Messages/sec"
                scale = "LINEAR"
              }
            }
          }
        },

        # Pub/Sub Undelivered Messages
        {
          xPos   = 6
          width  = 6
          height = 4
          widget = {
            title = "Pub/Sub - Undelivered Messages"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"pubsub_subscription\" AND resource.labels.subscription_id=\"${google_pubsub_subscription.event_subscription.name}\" AND metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = {
                label = "Messages"
                scale = "LINEAR"
              }
            }
          }
        },

        # Cloud Run Request Count
        {
          yPos   = 4
          width  = 6
          height = 4
          widget = {
            title = "Cloud Run - Request Rate"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${google_cloud_run_v2_service.event_processor.name}\" AND metric.type=\"run.googleapis.com/request_count\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields      = ["resource.service_name"]
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = {
                label = "Requests/sec"
                scale = "LINEAR"
              }
            }
          }
        },

        # Cloud Run Error Rate
        {
          xPos   = 6
          yPos   = 4
          width  = 6
          height = 4
          widget = {
            title = "Cloud Run - Error Rate"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${google_cloud_run_v2_service.event_processor.name}\" AND metric.type=\"run.googleapis.com/request_count\" AND metric.labels.response_code_class=\"2xx\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_RATE"
                        crossSeriesReducer = "REDUCE_SUM"
                        groupByFields      = ["resource.service_name"]
                      }
                    }
                  }
                  plotType       = "LINE"
                  targetAxis     = "Y1"
                  legendTemplate = "2xx Success"
                },
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${google_cloud_run_v2_service.event_processor.name}\" AND metric.type=\"run.googleapis.com/request_count\" AND metric.labels.response_code_class=\"4xx\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_RATE"
                        crossSeriesReducer = "REDUCE_SUM"
                        groupByFields      = ["resource.service_name"]
                      }
                    }
                  }
                  plotType       = "LINE"
                  targetAxis     = "Y1"
                  legendTemplate = "4xx Client Error"
                },
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${google_cloud_run_v2_service.event_processor.name}\" AND metric.type=\"run.googleapis.com/request_count\" AND metric.labels.response_code_class=\"5xx\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_RATE"
                        crossSeriesReducer = "REDUCE_SUM"
                        groupByFields      = ["resource.service_name"]
                      }
                    }
                  }
                  plotType       = "LINE"
                  targetAxis     = "Y1"
                  legendTemplate = "5xx Server Error"
                }
              ]
              yAxis = {
                label = "Requests/sec"
                scale = "LINEAR"
              }
            }
          }
        },

        # Cloud Run Latency
        {
          yPos   = 8
          width  = 6
          height = 4
          widget = {
            title = "Cloud Run - Request Latency (p50, p95, p99)"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${google_cloud_run_v2_service.event_processor.name}\" AND metric.type=\"run.googleapis.com/request_latencies\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_DELTA"
                        crossSeriesReducer = "REDUCE_PERCENTILE_50"
                        groupByFields      = ["resource.service_name"]
                      }
                    }
                  }
                  plotType       = "LINE"
                  legendTemplate = "p50"
                },
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${google_cloud_run_v2_service.event_processor.name}\" AND metric.type=\"run.googleapis.com/request_latencies\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_DELTA"
                        crossSeriesReducer = "REDUCE_PERCENTILE_95"
                        groupByFields      = ["resource.service_name"]
                      }
                    }
                  }
                  plotType       = "LINE"
                  legendTemplate = "p95"
                },
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${google_cloud_run_v2_service.event_processor.name}\" AND metric.type=\"run.googleapis.com/request_latencies\""
                      aggregation = {
                        alignmentPeriod    = "60s"
                        perSeriesAligner   = "ALIGN_DELTA"
                        crossSeriesReducer = "REDUCE_PERCENTILE_99"
                        groupByFields      = ["resource.service_name"]
                      }
                    }
                  }
                  plotType       = "LINE"
                  legendTemplate = "p99"
                }
              ]
              yAxis = {
                label = "Latency (ms)"
                scale = "LINEAR"
              }
            }
          }
        },

        # Cloud Run Instance Count
        {
          xPos   = 6
          yPos   = 8
          width  = 6
          height = 4
          widget = {
            title = "Cloud Run - Instance Count"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${google_cloud_run_v2_service.event_processor.name}\" AND metric.type=\"run.googleapis.com/container/instance_count\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MEAN"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields      = ["resource.service_name"]
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = {
                label = "Instances"
                scale = "LINEAR"
              }
            }
          }
        },

        # CPU Utilization
        {
          yPos   = 12
          width  = 6
          height = 4
          widget = {
            title = "Cloud Run - CPU Utilization"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${google_cloud_run_v2_service.event_processor.name}\" AND metric.type=\"run.googleapis.com/container/cpu/utilizations\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MEAN"
                      crossSeriesReducer = "REDUCE_MEAN"
                      groupByFields      = ["resource.service_name"]
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = {
                label = "Utilization"
                scale = "LINEAR"
              }
            }
          }
        },

        # Memory Utilization
        {
          xPos   = 6
          yPos   = 12
          width  = 6
          height = 4
          widget = {
            title = "Cloud Run - Memory Utilization"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${google_cloud_run_v2_service.event_processor.name}\" AND metric.type=\"run.googleapis.com/container/memory/utilizations\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_MEAN"
                      crossSeriesReducer = "REDUCE_MEAN"
                      groupByFields      = ["resource.service_name"]
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = {
                label = "Utilization"
                scale = "LINEAR"
              }
            }
          }
        },

        # Dead Letter Queue Messages
        {
          yPos   = 16
          width  = 6
          height = 4
          widget = {
            title = "Dead Letter Queue - Message Count"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"pubsub_subscription\" AND resource.labels.subscription_id=\"${google_pubsub_subscription.dead_letter_subscription.name}\" AND metric.type=\"pubsub.googleapis.com/subscription/num_undelivered_messages\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = {
                label = "Messages"
                scale = "LINEAR"
              }
              thresholds = [{
                value     = var.dlq_alert_threshold
                color     = "RED"
                direction = "ABOVE"
              }]
            }
          }
        },

        # Error Logs Count
        {
          xPos   = 6
          yPos   = 16
          width  = 6
          height = 4
          widget = {
            title = "Error Logs Count"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${google_cloud_run_v2_service.event_processor.name}\" AND severity>=ERROR"
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields      = ["resource.service_name"]
                    }
                  }
                }
                plotType = "LINE"
              }]
              yAxis = {
                label = "Errors/sec"
                scale = "LINEAR"
              }
            }
          }
        }
      ]
    }
  })

  project = var.project_id
}

# Error Reporting notification for errors
# Note: Cloud Error Reporting automatically captures errors from Cloud Run logs
# when errors are logged in the proper format (with @type: type.googleapis.com/google.devtools.clouderrorreporting.v1beta1.ReportedErrorEvent)
# or when structured logging is used with severity ERROR or higher

# Log-based metric for tracking error reporting
resource "google_logging_metric" "error_reporting_metric" {
  count = var.enable_error_reporting_metric ? 1 : 0

  name    = "${local.resource_prefix}_error_reporting"
  project = var.project_id

  filter = <<-EOT
    resource.type="cloud_run_revision"
    resource.labels.service_name="${google_cloud_run_v2_service.event_processor.name}"
    (severity>=ERROR OR jsonPayload.error!="" OR textPayload=~".*[Ee]rror.*" OR jsonPayload.@type=~".*ReportedErrorEvent.*")
  EOT

  metric_descriptor {
    metric_kind  = "DELTA"
    value_type   = "INT64"
    unit         = "1"
    display_name = "${var.environment} - Error Reporting Events"

    labels {
      key         = "error_type"
      value_type  = "STRING"
      description = "Type of error"
    }
  }

  label_extractors = {
    "error_type" = "EXTRACT(jsonPayload.error_type)"
  }
}

# Alert policy for Error Reporting
resource "google_monitoring_alert_policy" "error_reporting_alert" {
  count = var.enable_error_reporting_metric && var.enable_monitoring ? 1 : 0

  display_name = "${var.environment} - ${var.project_name} - Error Reporting Alert"
  combiner     = "OR"
  project      = var.project_id

  conditions {
    display_name = "High error rate detected"

    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${google_cloud_run_v2_service.event_processor.name}\" AND severity>=ERROR"
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.error_reporting_threshold

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_COUNT"
      }
    }
  }

  notification_channels = var.notification_channels

  alert_strategy {
    auto_close = "604800s"
  }

  documentation {
    content = <<-EOT
      Error Reporting has detected a high rate of errors in ${var.environment}.

      Actions:
      1. Check Error Reporting dashboard: https://console.cloud.google.com/errors?project=${var.project_id}
      2. Review Cloud Run logs for error details
      3. Check Cloud Trace for request traces: https://console.cloud.google.com/traces?project=${var.project_id}
      4. Verify recent deployments and rollback if necessary
    EOT
  }

  enabled = true
}

# Trace sampling configuration is handled at application level
# Cloud Trace is automatically enabled for Cloud Run services
# Applications should use OpenTelemetry or Cloud Trace SDK for instrumentation

# Log sink for long-term error analysis (optional)
resource "google_logging_project_sink" "error_sink_bigquery" {
  count = var.enable_error_log_sink ? 1 : 0

  name        = "${local.resource_prefix}-error-sink"
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${var.error_log_dataset_id}"
  project     = var.project_id

  filter = <<-EOT
    resource.type="cloud_run_revision"
    resource.labels.service_name="${google_cloud_run_v2_service.event_processor.name}"
    severity>=WARNING
  EOT

  unique_writer_identity = true

  bigquery_options {
    use_partitioned_tables = true
  }
}

# Grant BigQuery Data Editor role to log sink writer
resource "google_bigquery_dataset_iam_member" "error_sink_writer" {
  count = var.enable_error_log_sink ? 1 : 0

  dataset_id = var.error_log_dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.error_sink_bigquery[0].writer_identity
  project    = var.project_id
}
