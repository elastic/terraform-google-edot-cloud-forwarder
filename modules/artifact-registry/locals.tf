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
  # We need to create an image name based on the:
  # - Image name without tag and digest
  # - Image tag, if present
  # - Image digest, if present
  # Based on all three, we create a new image name containing the
  # name, tag and digest. Notice we add the digest as part of the
  # tag, since docker_tag does not support any digest in the image
  # name.
  #
  # Example:
  # - Contains only name:
  #   - Input: 'my-image'
  #   - Output: 'my-image:default'
  # - Contains name and tag:
  #   - Input: 'my-image:v1.0'
  #   - Output: 'my-image:v1.0'
  # - Contains name and digest:
  #   - Input: 'my-image@sha256:89c75210...'
  #   - Output: 'my-image:default-89c75210'
  # - Contains name, tag and digest:
  #   - Input: 'my-image:v1.0@sha256:89c75210...'
  #   - Output: 'my-image:v1.0-89c75210'
  image_path_parts      = split("/", var.image)
  image_name_tag_digest = local.image_path_parts[length(local.image_path_parts) - 1]
  image_digest_parts    = split("@", local.image_name_tag_digest)
  image_name_and_tag    = local.image_digest_parts[0]
  image_digest          = length(local.image_digest_parts) > 1 ? substr(local.image_digest_parts[1], 7, 8) : "" # remove "sha256-"
  image_tag_parts       = split(":", local.image_name_and_tag)
  image_name            = local.image_tag_parts[0]
  image_tag             = length(local.image_tag_parts) > 1 ? local.image_tag_parts[1] : "default"
  target_name = local.image_digest != "" ? (
    "${local.image_name}:${local.image_tag}-${local.image_digest}"
  ) : "${local.image_name}:${local.image_tag}"
}
