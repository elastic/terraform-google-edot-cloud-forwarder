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

# Create a standard artifact registry to store the ECF image.
# We use a Standard Repository (not a Remote) to create an immutable
# snapshot of the ECF image. This guarantees:
# - Protection against Docker Hub rate limits and outages.
# - Immutability, ensuring the deployed image digest never changes,
#    even if the upstream registry overwrites a tag.
resource "google_artifact_registry_repository" "ecf" {
  location      = var.region
  repository_id = "${var.ecf_asset_prefix}-ecf"
  description   = "Docker image registry for Elastic Cloud Forwarder"
  format        = "DOCKER"

  provisioner "local-exec" {
    command = "gcloud auth configure-docker ${var.region}-docker.pkg.dev"
  }

  cleanup_policies {
    id     = "keep-last-3-used"
    action = "KEEP"

    most_recent_versions {
      # This ensures the 3 most recently pushed/tagged images are kept.
      package_name_prefixes = ["*"] # all images
      keep_count            = 3
    }
  }
}

# Create a service account for pushing images to Artifact Registry
resource "google_service_account" "artifact_registry_writer" {
  # limit to 30 characters long and don't let it end on -
  account_id   = trimsuffix(substr("${var.ecf_asset_prefix}-artifact-rgst-wr", 0, 30), "-")
  display_name = "Artifact Registry Writer"
  description  = "Service account for pushing ECF images to the ECF Artifact Registry"
}

# Pull docker image from registry (or automatically use pre-pulled local image)
resource "docker_image" "ecf_public_image" {
  name = var.image
}

# Give the image its target location (path and name) so it can be uploaded by docker_registry_image
resource "docker_tag" "tagged_w_dest" {
  source_image = docker_image.ecf_public_image.image_id
  target_image = "${google_artifact_registry_repository.ecf.location}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.ecf.name}/${local.target_name}"
}

# Grant the writer role to the service account for only this repository
resource "google_artifact_registry_repository_iam_member" "artifact_registry_writer" {
  project    = google_artifact_registry_repository.ecf.project
  location   = google_artifact_registry_repository.ecf.location
  repository = google_artifact_registry_repository.ecf.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.artifact_registry_writer.email}"
}

# Create a long-lived service account key for pushing images to Artifact Registry
resource "google_service_account_key" "artifact_registry_writer" {
  service_account_id = google_service_account.artifact_registry_writer.id
}

# Push image to this module's artifact registry; path specified within docker_tag
resource "docker_registry_image" "ecf_pushed_image" {
  name = docker_tag.tagged_w_dest.target_image
  # Although counter-intuitive, since the registry will be destroyed,
  # we don't want to try and delete the image as well.
  # This can cause Terraform to error.
  keep_remotely = true

  auth_config {
    address = "${google_artifact_registry_repository.ecf.location}-docker.pkg.dev"
    # special username literal:
    # see: https://cloud.google.com/artifact-registry/docs/docker/authentication#json-key
    username = "_json_key_base64"
    password = google_service_account_key.artifact_registry_writer.private_key
  }
}

# Grant Cloud Run service account permission to read from the module-managed artifact registry
# This is only needed when the module creates its own registry
resource "google_artifact_registry_repository_iam_member" "cloud_run_artifact_registry_reader" {
  repository = google_artifact_registry_repository.ecf.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${var.cloud_run_service_account_email}"
}
