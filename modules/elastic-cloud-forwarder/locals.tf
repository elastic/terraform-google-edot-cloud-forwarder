locals {
  is_artifact_registry_image = (
    # TODO: Revisit making this more robust to protect against corner cases
    strcontains(var.image, "gcr.io") || strcontains(var.image, "pkg.dev")
  )

  # Don't create the artifact registry repository if the image is already from an artifact registry
  should_create_artifact_registry_repository = !local.is_artifact_registry_image

  # use the pushed image if the artifact registry repository was created, 
  # otherwise use the original image
  ecf_image_name = (
    local.should_create_artifact_registry_repository
    ? docker_registry_image.ecf_pushed_image[0].name
    : var.image
  )

}