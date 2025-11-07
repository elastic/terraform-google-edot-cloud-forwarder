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

resource "google_artifact_registry_repository" "ecf" {
  count = local.should_create_artifact_registry_repository ? 1 : 0
  location = var.region
  repository_id = "${var.ecf_asset_prefix}-ecf"
  description   = "Docker image registry for EDOT Cloud Forwarder"
  format        = "DOCKER"

  provisioner "local-exec" {
    command = "gcloud auth configure-docker ${var.region}-docker.pkg.dev"
  }
}

# Pull docker image from the public registry
# Q: is the docker daemon available where needed?
resource "docker_image" "ecf_public_image" {
  count = local.should_create_artifact_registry_repository ? 1 : 0

  name = var.image
}

resource "docker_tag" "tagged_w_dest" {
  count = local.should_create_artifact_registry_repository ? 1 : 0

  source_image = docker_image.ecf_public_image[0].name
  target_image = "${google_artifact_registry_repository.ecf[0].location}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.ecf[0].name}/${var.image}"
}

# TODO: test and see if auth works for all this
resource "docker_registry_image" "ecf_pushed_image" {
  count = local.should_create_artifact_registry_repository ? 1 : 0

  name = docker_tag.tagged_w_dest[0].target_image
}

# Create a service account to use in the google cloud run to grant the least
# amount of privileges.
resource "google_service_account" "cloud_run" {
  # limit to 30 characters long
  account_id = substr("${var.ecf_asset_prefix}-cloud-run", 0, 30)
}