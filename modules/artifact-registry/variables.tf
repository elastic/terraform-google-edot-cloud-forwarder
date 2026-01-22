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

variable "project" {
  description = "The name of the Google Cloud Platform project in which to create the resources."
  type        = string
}

variable "region" {
  description = "The Google Cloud Platform region in which to create the resources."
  type        = string
}

variable "ecf_asset_prefix" {
  description = "Prefix for the ECF assets' names. Multiple simultaneous deployments should have different prefixes, otherwise, name collisions and associated failures will occur. The prefix must start with a lowercase letter; contain only lowercase letters, numbers, and hyphens; and end with a lowercase letter or number (not a hyphen)."
  type        = string
}

variable "image" {
  description = "The collector image."
  type        = string
}

variable "cloud_run_service_account_email" {
  description = "Cloud Run service account email."
  type        = string
}
