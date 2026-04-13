# Artifact Registry Submodule

This submodule creates a private Google Artifact Registry repository and manages ECF Docker images for improved reliability and security.

## Purpose

- Immutable snapshots: Creates immutable copies of ECF images to protect against upstream changes
- Availability: Eliminates dependency on external registries (Docker Hub rate limits, outages)
- Security: Provides private image storage with controlled access
- Performance: Regional image storage for faster container startup

## Usage

This submodule is automatically used by the parent module when:
- `force_ecf_artifact_registry = true`, or  
- The source `image` is from a public registry (not already in Artifact Registry)

## Cleanup Policy

- Automatically keeps the 3 most recently used images
- Removes older images to control storage costs

## Technical Reference

The following sections provide detailed technical information about this submodule's requirements, resources, inputs, and outputs.

<!-- BEGIN_TF_DOCS -->
#### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.9.0 |
| <a name="requirement_docker"></a> [docker](#requirement_docker) | >= 3.0 |
| <a name="requirement_google"></a> [google](#requirement_google) | >= 7.0.0 |

#### Providers

| Name | Version |
|------|---------|
| <a name="provider_docker"></a> [docker](#provider_docker) | >= 3.0 |
| <a name="provider_google"></a> [google](#provider_google) | >= 7.0.0 |

#### Modules

No modules.

#### Resources

| Name | Type |
|------|------|
| [docker_image.ecf_public_image](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/image) | resource |
| [docker_registry_image.ecf_pushed_image](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/registry_image) | resource |
| [docker_tag.tagged_w_dest](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/tag) | resource |
| [google_artifact_registry_repository.ecf](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository) | resource |
| [google_artifact_registry_repository_iam_member.artifact_registry_writer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository_iam_member) | resource |
| [google_artifact_registry_repository_iam_member.cloud_run_artifact_registry_reader](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository_iam_member) | resource |
| [google_service_account.artifact_registry_writer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account_key.artifact_registry_writer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_key) | resource |

#### Inputs

| Name | Description | Type |
|------|-------------|------|
| <a name="input_cloud_run_service_account_email"></a> [cloud_run_service_account_email](#input_cloud_run_service_account_email) | Cloud Run service account email. | `string` |
| <a name="input_ecf_asset_prefix"></a> [ecf_asset_prefix](#input_ecf_asset_prefix) | Prefix for the ECF assets' names. Multiple simultaneous deployments should have different prefixes, otherwise, name collisions and associated failures will occur. The prefix must start with a lowercase letter; contain only lowercase letters, numbers, and hyphens; and end with a lowercase letter or number (not a hyphen). | `string` |
| <a name="input_image"></a> [image](#input_image) | The collector image. | `string` |
| <a name="input_project"></a> [project](#input_project) | The name of the Google Cloud Platform project in which to create the resources. | `string` |
| <a name="input_region"></a> [region](#input_region) | The Google Cloud Platform region in which to create the resources. | `string` |

#### Outputs

| Name | Description |
|------|-------------|
| <a name="output_image"></a> [image](#output_image) | ECF image name. |
<!-- END_TF_DOCS -->