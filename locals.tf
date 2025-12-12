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
  # if the image is already from an artifact registry.
  create_artifact_registry = var.force_ecf_artifact_registry || !local.is_artifact_registry_image

  # Use the pushed image if the artifact registry repository was created,
  # otherwise use the original image.
  ecf_image_name = length(module.artifact_registry) == 1 ? module.artifact_registry[0].image : var.image

  logs_source_bucket_name = (
    var.logs_source_bucket_name == ""
    ? "${var.ecf_asset_prefix}-logs"
    : var.logs_source_bucket_name
  )

  pubsub_service_account = "service-${data.google_project.current.number}@gcp-sa-pubsub.iam.gserviceaccount.com"

  # get value of memory as a number and get the unit as well
  ecf_memory_numeric_value_str = regex("[0-9\\.]+", var.ecf_container_memory)
  ecf_memory_numeric_value     = tonumber(local.ecf_memory_numeric_value_str)
  unit_suffix_clean            = upper(trimprefix(var.ecf_container_memory, local.ecf_memory_numeric_value_str))

  # see supported unit values in
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service#limits-1
  memory_in_mib = (
    startswith(local.unit_suffix_clean, "K") ? local.ecf_memory_numeric_value / 1024 :
    startswith(local.unit_suffix_clean, "M") ? local.ecf_memory_numeric_value :
    startswith(local.unit_suffix_clean, "G") ? local.ecf_memory_numeric_value * 1024 :
    startswith(local.unit_suffix_clean, "T") ? local.ecf_memory_numeric_value * 1024 * 1024 :
    startswith(local.unit_suffix_clean, "P") ? local.ecf_memory_numeric_value * 1024 * 1024 * 1024 :
    startswith(local.unit_suffix_clean, "E") ? local.ecf_memory_numeric_value * 1024 * 1024 * 1024 * 1024 :
    # Assume MiB if no unit specified
    local.ecf_memory_numeric_value
  )

  # Calculate 90% and use MiB (Go's preferred unit)
  gomemlimit_mib = floor(local.memory_in_mib * 0.9)
  # see the supported suffixes for GOMEMLIMIT: run $(go doc runtime/debug.SetMemoryLimit)
  gomemlimit_value = "${local.gomemlimit_mib}MiB"
}
