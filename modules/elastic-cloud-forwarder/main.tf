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
  secret_data_wo = var.elastic_api_key
}

resource "google_artifact_registry_repository" "ecftf" {
  count = local.should_create_artifact_registry_repository ? 1 : 0
  location = var.region
  repository_id = "${var.ecf_asset_prefix}-ecftf"
  description   = "Docker image registry for EDOT Cloud Forwarder"
  format        = "DOCKER"

  provisioner "local-exec" {
    command = "gcloud auth configure-docker ${var.region}-docker.pkg.dev"
  }
}

# Pull docker image from registry (or automatically use pre-pulled local image)
resource "docker_image" "ecf_public_image" {
  count = local.should_create_artifact_registry_repository ? 1 : 0
  name = var.image
}

resource "docker_tag" "tagged_w_dest" {
  count = local.should_create_artifact_registry_repository ? 1 : 0

  source_image = docker_image.ecf_public_image[0].image_id
  target_image = "${google_artifact_registry_repository.ecftf[0].location}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.ecftf[0].name}/ecf:latest"
}

# Create a service account for pushing images to Artifact Registry
resource "google_service_account" "artifact_registry_writer" {
  count = local.should_create_artifact_registry_repository ? 1 : 0

  account_id = substr("${var.ecf_asset_prefix}-artifact-rgst-wr", 0, 30)
  display_name = "Artifact Registry Writer"
  description = "Service account for pushing ECF images to the ECF Artifact Registry"
}

# Grant the writer role to the service account for only this repository
resource "google_artifact_registry_repository_iam_member" "artifact_registry_writer" {
  count = local.should_create_artifact_registry_repository ? 1 : 0

  # TODO: see if we can remove project and location from here
  project = google_artifact_registry_repository.ecftf[0].project
  location = google_artifact_registry_repository.ecftf[0].location
  repository = google_artifact_registry_repository.ecftf[0].name
  role = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.artifact_registry_writer[0].email}"
}

# Create a long-lived service account key for pushing images to Artifact Registry
resource "google_service_account_key" "artifact_registry_writer" {
  count = local.should_create_artifact_registry_repository ? 1 : 0

  service_account_id = google_service_account.artifact_registry_writer[0].id
}

resource "docker_registry_image" "ecf_pushed_image" {
  count = local.should_create_artifact_registry_repository ? 1 : 0

  name = docker_tag.tagged_w_dest[0].target_image
  # Although counter-intuitive, since the registry will be destroyed,
  # we don't want to try and delete the image as well.
  # This can cause Terraform to error.
  keep_remotely = true

  auth_config {
    address = "${google_artifact_registry_repository.ecftf[0].location}-docker.pkg.dev"
    # special username literal:
    # see: https://cloud.google.com/artifact-registry/docs/docker/authentication#json-key
    username = "_json_key_base64"
    password = google_service_account_key.artifact_registry_writer[0].private_key
  }
}

# Create a service account to use in the google cloud run to grant the least
# amount of privileges.
resource "google_service_account" "cloud_run" {
  # limit to 30 characters long
  account_id = substr("${var.ecf_asset_prefix}-cloud-run", 0, 30)
}

# Grant Cloud Run service account permission to read from the module-managed artifact registry
# This is only needed when the module creates its own registry
resource "google_artifact_registry_repository_iam_member" "cloud_run_artifact_registry_reader" {
  count = local.should_create_artifact_registry_repository ? 1 : 0

  repository = google_artifact_registry_repository.ecftf[0].name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.cloud_run.email}"
}

# Grant permissions to cloud run service account.
resource "google_project_iam_member" "cloud_run_permissions" {

  for_each = toset([
    "roles/artifactregistry.reader",
    "roles/secretmanager.secretAccessor",
    "roles/logging.logWriter", # give permission to cloud run to write log entries so we can tail its logs
    "roles/storage.objectViewer",
  ])

  project = var.project
  role    = each.key
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}

# Create a service account to use in the Pub/Sub subscription.
resource "google_service_account" "pubsub" {
  
  # limit to 30 characters long
  account_id = substr("${var.ecf_asset_prefix}-pubsub", 0, 30)
}

# Grant permissions to ECF service account.
resource "google_project_iam_member" "pubsub_permissions" {

  project = var.project
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.pubsub.email}"
}

# Create Pub/Sub topic for logs.
resource "google_pubsub_topic" "logs" {
  name = "${var.ecf_asset_prefix}-logs-ecf"
}

# Create Pub/Sub dead letter topic.
resource "google_pubsub_topic" "dead_letter" {
  name = "${var.ecf_asset_prefix}-dead-letter-ecf"
}