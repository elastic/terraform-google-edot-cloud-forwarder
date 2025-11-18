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

# Grant permissions to cloud run service account for telemetry API key
resource "google_secret_manager_secret_iam_member" "telemetry_api_key" {
  count = var.enable_telemetry ? 1 : 0

  project = google_secret_manager_secret.telemetry_api_key[0].project
  secret_id = google_secret_manager_secret.telemetry_api_key[0].secret_id
  role = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cloud_run.email}"
}
