# Terraform Google Elastic Cloud Forwarder

Deploys an Elastic Cloud Forwarder on Google Cloud Platform to automatically stream logs from different sources to Elastic Cloud.

## Architecture

The overall architecture is like this:

![overview](img/edot-cloud-forwarder-gcp-overview.png)

The module deploys everything except for the `Elastic Cloud` section, as it expects it to be present already.

## Usage

### Basic Example

```hcl
module "elastic_cloud_forwarder" {
  source = "./modules/elastic-cloud-forwarder"

  project               = "my-gcp-project"
  region                = "us-central1"
  image                 = "docker.elastic.co/observability/elastic-cloud-forwarder:latest"
  ecf_exporter_endpoint = "https://my-deployment.es.us-central1.gcp.cloud.es.io:443"
  ecf_exporter_api_key  = var.elastic_api_key
}
```

### Advanced Configuration

```hcl
module "elastic_cloud_forwarder" {
  source = "./modules/elastic-cloud-forwarder"

  # Required parameters
  project               = "my-gcp-project"
  region                = "us-central1"
  image                 = "docker.elastic.co/observability/elastic-cloud-forwarder:latest"
  ecf_exporter_endpoint = "https://my-deployment.es.us-central1.gcp.cloud.es.io:443"
  ecf_exporter_api_key  = var.elastic_api_key

  # Optional configuration
  ecf_asset_prefix                    = "production-logs"
  logs_source_bucket_name             = "existing-logs-bucket"
  include_metadata                    = true
  enable_cloud_observability_logging  = true

  # Resource limits
  ecf_container_cpu      = "2"
  ecf_container_memory   = "1Gi"
  max_ecf_instance_count = 50

  # Retry configuration
  retry_minimum_backoff  = 10
  retry_maximum_backoff  = 300
  retry_maximum_attempts = 10

  # Telemetry (optional)
  enable_telemetry = true
  telemetry_endpoint = "https://telemetry.elastic.co"
  telemetry_api_key = var.telemetry_api_key
  telemetry_additional_attributes = {
    environment = "production"
    team        = "platform"
  }
}
```

### Using Existing Resources

```hcl
module "elastic_cloud_forwarder" {
  source = "./modules/elastic-cloud-forwarder"

  project                     = "my-gcp-project"
  region                      = "us-central1"
  image                       = "gcr.io/my-project/custom-ecf:v1.0.0"
  ecf_exporter_endpoint       = "https://my-deployment.es.us-central1.gcp.cloud.es.io:443"
  ecf_exporter_api_key        = var.elastic_api_key
  logs_source_bucket_name     = "my-existing-logs-bucket"
  force_ecf_artifact_registry = false
}
```

## Prerequisites

- Google Cloud Project with Cloud Run, Pub/Sub, Cloud Storage, Secret Manager, and Artifact Registry APIs enabled.
- Elastic Cloud deployment with API key.

## Documentation

For complete variable descriptions, outputs, architecture details, and troubleshooting, see the [detailed module documentation](./modules/elastic-cloud-forwarder/README.md).

## License

This module is licensed under the Elasticsearch License. See [LICENSE](./LICENSE.txt) for details.