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

output "ecftf_managed_artifact_registry_used" {
  description = "Whether the ECF Terraform module used its own artifact registry."
  value       = local.should_create_artifact_registry_repository
}

output "artifact_registry_writer_key_secret_id" {
  description = "Secret ID for the Artifact Registry writer service account key, if one was created (stored in Secret Manager)."
  value = (
    local.should_create_artifact_registry_repository
    ? google_secret_manager_secret.artifact_registry_writer_key[0].secret_id
    : "ECF Terraform module did not create an Artifact Registry writer key"
  )
}

output "artifact_registry_writer_key_version" {
  description = "Version of the Artifact Registry writer service account key, if one was created (stored in Secret Manager)."
  value = (
    local.should_create_artifact_registry_repository
    ? google_secret_manager_secret_version.artifact_registry_writer_key[0].version
    : "ECF Terraform module did not create an Artifact Registry writer key"
  )
}

output "pubsub_google_service_account_email" {
  description = "Email of the Pub/Sub Google Service Account."
  value       = google_service_account.pubsub.email
}