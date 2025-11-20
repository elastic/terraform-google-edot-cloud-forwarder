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

locals {
  is_artifact_registry_image = (
    # TODO: Revisit making this more robust to protect against corner cases
    strcontains(var.image, "gcr.io") || strcontains(var.image, "pkg.dev")
  )

  # Unless forced, don't create the artifact registry repository 
  #if the image is already from an artifact registry.
  should_create_artifact_registry_repository = var.force_ecf_artifact_registry || !local.is_artifact_registry_image

  # use the pushed image if the artifact registry repository was created, 
  # otherwise use the original image
  ecf_image_name = (
    local.should_create_artifact_registry_repository
    ? docker_registry_image.ecf_pushed_image[0].name
    : var.image
  )

  logs_source_bucket_name = (
    var.logs_source_bucket_name == ""
    ? "${var.ecf_asset_prefix}-logs-ecf"
    : var.logs_source_bucket_name
  )

  pubsub_service_account = "service-${data.google_project.current.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}