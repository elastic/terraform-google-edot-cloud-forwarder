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
resource "google_secret_manager_secret" "elastic_api_key" {
  secret_id = "${var.ecf_asset_prefix}-elastic-api-key"
  replication {
    auto {}
  }
}

# Resource to save the API key in the secret.
resource "google_secret_manager_secret_version" "elastic_api_key" {
  # Note that this is not the secret_id, but the secret's resource idenitifier,
  # e.g. projects/{{project}}/secrets/{{secret_id}}
  secret      = google_secret_manager_secret.elastic_api_key.id
  secret_data = var.elastic_api_key
}

data "google_artifact_registry_docker_image" "ecf" {
  image_name    = "${var.image_name}:latest"
  location      = var.region
  repository_id = var.registry_name
}

# Create a service account to use in the google cloud run to grant the least
# amount of privileges.
resource "google_service_account" "cloud_run" {
  # limit to 30 characters long
  account_id = substr("${var.ecf_asset_prefix}-cloud-run", 0, 30)
}