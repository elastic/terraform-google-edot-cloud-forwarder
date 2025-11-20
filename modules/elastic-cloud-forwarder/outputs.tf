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


output "elastic_api_key_secret_id" {
  description = "Elastic API key secret ID for exporting logs via the Elastic Cloud Forwarder."
  value       = google_secret_manager_secret.elastic_api_key.secret_id
}

output "elastic_api_key_version" {
  description = "Elastic API key version for exporting logs via the Elastic Cloud Forwarder."
  value       = google_secret_manager_secret_version.elastic_api_key.version
}

output "ecf_docker_image_uri" {
  description = "URI of the ECF Docker image."
  value       = local.ecf_image_name
}

output "ecf_cloud_run_service_account_email" {
  description = "Email of the Cloud Run service account."
  value       = google_service_account.cloud_run.email
}

output "ecf_managed_artifact_registry_used" {
  description = "Whether the ECF Terraform module used its own artifact registry."
  value       = local.should_create_artifact_registry_repository
}

output "pubsub_google_service_account_email" {
  description = "Email of the Pub/Sub Google Service Account."
  value       = google_service_account.pubsub.email
}

output "logs_topic_id" {
  description = "ID of the Pub/Sub logs topic."
  value       = google_pubsub_topic.logs.id
}

output "logs_topic_name" {
  description = "Name of the Pub/Sub logs topic."
  value       = google_pubsub_topic.logs.name
}

output "dead_letter_topic_id" {
  description = "ID of the Pub/Sub dead letter topic."
  value       = google_pubsub_topic.dead_letter.id
}

output "logs_source_bucket_name" {
  description = "Name of the GCS logs source bucket."
  value       = local.logs_source_bucket_name
}

output "google_cloud_run_v2_service_name" {
  description = "Name of the google cloud run service"
  value       = google_cloud_run_v2_service.ecf.name
}

output "google_cloud_run_v2_service_uri" {
  description = "URI of the google cloud run service"
  value       = google_cloud_run_v2_service.ecf.uri
}

output "google_cloud_run_v2_service_latest_created_revision" {
  description = "Revision of the google cloud run service"
  value       = google_cloud_run_v2_service.ecf.latest_created_revision
}

output "logs_subscription_id" {
  description = "ID of the Pub/Sub subscription for the logs topic."
  value       = google_pubsub_subscription.logs.id
}

output "failed_messages_bucket_name" {
  description = "Name of the GCS bucket to which failed messages are sent."
  value       = google_storage_bucket.failed_messages.name
}