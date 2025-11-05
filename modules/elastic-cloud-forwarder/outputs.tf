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

output "ecf_google_artifact_registry_docker_image_self_link_uri" {
  description = "URI of the ECF Docker image."
  value       = data.google_artifact_registry_docker_image.ecf.self_link
}

output "ecf_cloud_run_service_account_email" {
  description = "Email of the Cloud Run service account."
  value       = google_service_account.cloud_run.email
}