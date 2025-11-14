# This file adds the resources to support enabling the internal telemetry.

# Store the telemetry API key in a secret.
resource "google_secret_manager_secret" "telemetry_api_key" {
  count     = var.enable_telemetry ? 1 : 0
  secret_id = "${var.ecf_asset_prefix}-telemetry-api-key"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "telemetry_api_key" {
  count       = var.enable_telemetry ? 1 : 0
  secret      = google_secret_manager_secret.telemetry_api_key[0].id
  secret_data = var.telemetry_api_key
}
