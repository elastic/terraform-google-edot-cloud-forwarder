# ELASTICSEARCH CONFIDENTIAL
# __________________
#
#  Copyright Elasticsearch B.V. All rights reserved.
#
# NOTICE:  All information contained herein is, and remains
# the property of Elasticsearch B.V. and its suppliers, if any.
# The intellectual and technical concepts contained herein
# are proprietary to Elasticsearch B.V. and its suppliers and
# may be covered by U.S. and Foreign Patents, patents in
# process, and are protected by trade secret or copyright
# law.  Dissemination of this information or reproduction of
# this material is strictly forbidden unless prior written
# permission is obtained from Elasticsearch B.V.

# We need a secret in which to save the API key from the serverless project.
# Note that the "version" in google_secret_manager_secret_version actually
# receives the secret_data
resource "google_secret_manager_secret" "exporter_api_key" {
  secret_id = "${var.ecf_asset_prefix}-elastic-api-key"
  replication {
    auto {}
  }
}

# Resource to save the API key in the secret.
resource "google_secret_manager_secret_version" "exporter_api_key" {
  # Note that this is not the secret_id, but the secret's resource identifier,
  # e.g. projects/{{project}}/secrets/{{secret_id}}
  secret         = google_secret_manager_secret.exporter_api_key.id
  secret_data_wo = var.ecf_exporter_api_key
}

# Create a service account to use in the google cloud run to grant the least
# amount of privileges.
resource "google_service_account" "cloud_run" {
  # limit to 30 characters long and don't let it end on -
  account_id = trimsuffix(substr("${var.ecf_asset_prefix}-cloud-run", 0, 30), "-")
}

# Give permission to cloud run to write log entries so we can tail its logs
resource "google_project_iam_member" "cloud_run_permissions" {
  count = var.enable_cloud_observability_logging ? 1 : 0

  project = var.project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}

# Grant permission to the cloud run service account on the source bucket
resource "google_storage_bucket_iam_member" "cloud_run_permissions" {
  bucket = local.logs_source_bucket_name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.cloud_run.email}"
  timeouts {
    create = "5m"
  }
  depends_on = [google_storage_bucket.logs]
}

# Grant permission to cloud run service account for the exporter API key
resource "google_secret_manager_secret_iam_member" "exporter_api_key" {
  project   = google_secret_manager_secret.exporter_api_key.project
  secret_id = google_secret_manager_secret.exporter_api_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloud_run.email}"
}

# Create a service account to use in the Pub/Sub subscription.
resource "google_service_account" "pubsub" {
  # limit to 30 characters long and don't let it end on -
  account_id = trimsuffix(substr("${var.ecf_asset_prefix}-pubsub", 0, 30), "-")
}

# Grant permissions to pubsub to invoke cloud run
resource "google_cloud_run_v2_service_iam_member" "pubsub_permissions" {
  project  = google_cloud_run_v2_service.ecf.project
  location = google_cloud_run_v2_service.ecf.location
  name     = google_cloud_run_v2_service.ecf.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.pubsub.email}"
}

# Create Pub/Sub topic for logs.
resource "google_pubsub_topic" "logs" {
  name = "${var.ecf_asset_prefix}-logs"
}

# Create Pub/Sub dead letter topic.
resource "google_pubsub_topic" "dead_letter" {
  name = "${var.ecf_asset_prefix}-dead-letter"
}

# Create a GCS bucket for logs.
resource "google_storage_bucket" "logs" {
  count = var.logs_source_bucket_name == "" ? 1 : 0

  name                        = local.logs_source_bucket_name
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

# Enable GCS notifications to PubSub
resource "google_storage_notification" "notification" {
  bucket         = local.logs_source_bucket_name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.logs.id
  # we only want to get a  notification when a new log file is created
  event_types = ["OBJECT_FINALIZE"]
  depends_on = [
    google_pubsub_topic_iam_member.allow_storage_to_pubsub,
    google_storage_bucket.logs,
  ]
}

# Enable notifications by giving the correct IAM permission to the unique service account.
# Leverage the project's unique google storage service account. This is needed for GCS operations.
data "google_storage_project_service_account" "gcs_account" {}

resource "google_pubsub_topic_iam_member" "allow_storage_to_pubsub" {
  topic  = google_pubsub_topic.logs.id
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
}

# Get current Google project data.
data "google_project" "current" {}

# Allow Pub/Sub to create tokens, as push requires authentication.
resource "google_project_iam_member" "allow_token" {
  project = var.project
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${local.pubsub_service_account}"
}

# Create the artifact registry with ECF image, if needed.
module "artifact_registry" {
  count                           = local.create_artifact_registry ? 1 : 0
  source                          = "./artifact-registry"
  cloud_run_service_account_email = google_service_account.cloud_run.email
  ecf_asset_prefix                = var.ecf_asset_prefix
  image                           = var.image
  project                         = var.project
  region                          = var.region
}

# Deploy the cloud run service where ECF is running.
resource "google_cloud_run_v2_service" "ecf" {
  name                = var.ecf_asset_prefix
  location            = var.region
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"

  scaling {
    max_instance_count = var.max_ecf_instance_count
  }

  template {
    service_account                  = google_service_account.cloud_run.email
    max_instance_request_concurrency = var.max_instance_request_concurrency

    containers {
      name  = "ecf-collector"
      image = local.ecf_image_name
      args = [
        # See https://github.com/open-telemetry/opentelemetry-collector/blob/main/docs/rfcs/component-universal-telemetry.md
        var.enable_telemetry ? "--feature-gates=telemetry.newPipelineTelemetry" : "",
      ]

      resources {
        limits = {
          "cpu"    = var.ecf_container_cpu
          "memory" = var.ecf_container_memory
        }
        cpu_idle = var.ecf_cpu_idle
      }

      ports {
        container_port = 8080
      }

      env {
        name  = "OTEL_EXPORTER_OTLP_ENDPOINT"
        value = var.ecf_exporter_endpoint
      }

      env {
        name = "ELASTIC_API_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.exporter_api_key.secret_id
            version = google_secret_manager_secret_version.exporter_api_key.version
          }
        }
      }

      env {
        name  = "METRICS_LEVEL"
        value = var.enable_telemetry ? "detailed" : "none"
      }

      env {
        name  = "TELEMETRY_ENDPOINT"
        value = var.telemetry_endpoint
      }

      env {
        name  = "ES_MAPPING_MODE"
        value = var.es_mapping_mode
      }
      env {
        name  = "INCLUDE_METADATA"
        value = var.include_metadata
      }

      env {
        name  = "PROCESSORS_LIST"
        value = var.include_metadata ? "[\"attributes\"]" : "[]"
      }

      env {
        name = "TELEMETRY_API_KEY"
        dynamic "value_source" {
          for_each = var.enable_telemetry ? [1] : []
          content {
            secret_key_ref {
              secret  = google_secret_manager_secret.telemetry_api_key[0].secret_id
              version = google_secret_manager_secret_version.telemetry_api_key[0].version
            }
          }
        }
      }

      env {
        name  = "ADDITIONAL_TELEMETRY_ATTR"
        value = length(var.telemetry_additional_attributes) == 0 ? "" : yamlencode(var.telemetry_additional_attributes)
      }

      env {
        name  = "GOMEMLIMIT"
        value = local.gomemlimit_value
      }
    }
  }

  depends_on = [
    google_secret_manager_secret_version.exporter_api_key,
    google_secret_manager_secret_version.telemetry_api_key,
    google_project_iam_member.cloud_run_permissions,
    google_storage_bucket_iam_member.cloud_run_permissions,
    google_secret_manager_secret_iam_member.exporter_api_key,
    google_secret_manager_secret_iam_member.telemetry_api_key,
    module.artifact_registry,
  ]
}

# The Cloud Pub/Sub service account for this project needs the publisher role to
# publish dead-lettered messages to the dead letter topic.
resource "google_pubsub_topic_iam_member" "dead_letter_publisher" {
  topic  = google_pubsub_topic.dead_letter.id
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${local.pubsub_service_account}"
}

# Trigger cloud run when message is published on the Pub/Sub topic.
resource "google_pubsub_subscription" "logs" {
  name  = "${var.ecf_asset_prefix}-logs"
  topic = google_pubsub_topic.logs.id

  push_config {
    push_endpoint = google_cloud_run_v2_service.ecf.uri
    oidc_token {
      service_account_email = google_service_account.pubsub.email
    }
  }

  # never let this subscription expire
  expiration_policy {
    ttl = ""
  }

  # give ECF the maximum allowed time to consume messages, so that Pub/Sub
  # does not keep retrying sending a message, making ECF process the same
  # logs multiple times in a loop
  ack_deadline_seconds = 600

  retry_policy {
    minimum_backoff = "${var.retry_minimum_backoff}s"
    maximum_backoff = "${var.retry_maximum_backoff}s"
  }

  dead_letter_policy {
    max_delivery_attempts = var.retry_maximum_attempts
    dead_letter_topic     = google_pubsub_topic.dead_letter.id
  }

  depends_on = [
    google_cloud_run_v2_service_iam_member.pubsub_permissions
  ]
}

resource "google_pubsub_subscription_iam_member" "dead_letter_subscriber" {
  subscription = google_pubsub_subscription.logs.id
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${local.pubsub_service_account}"
}

# Create a GCS bucket for failed messages.
resource "google_storage_bucket" "failed_messages" {
  name                        = "${var.ecf_asset_prefix}-failed"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

# Add permissions to place files in the GCS bucket meant for failed messages.
resource "google_storage_bucket_iam_member" "failed_messages_permissions" {
  for_each = toset([
    "roles/storage.legacyBucketReader",
    "roles/storage.objectCreator",
  ])

  bucket = google_storage_bucket.failed_messages.name
  role   = each.key
  member = "serviceAccount:${local.pubsub_service_account}"
}

# Define the dead letter Pub/Sub subscription.
resource "google_pubsub_subscription" "dead_letter" {
  name  = "${var.ecf_asset_prefix}-dead-letter"
  topic = google_pubsub_topic.dead_letter.id

  cloud_storage_config {
    bucket = google_storage_bucket.failed_messages.name

    max_duration = "${var.dead_letter_to_gcs_interval}s"

    # TODO Maybe we should give the customer the option for avro files.
    # See: https://cloud.google.com/pubsub/docs/create-cloudstorage-subscription#file_format
    # Check TF: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription
    # The customer would then be able to see metadata, like subscription, message ID, etc.
    # Files are bigger in size as well (-> more costly).
  }

  # never let this subscription expire
  expiration_policy {
    ttl = ""
  }

  depends_on = [
    google_storage_bucket_iam_member.failed_messages_permissions
  ]
}
