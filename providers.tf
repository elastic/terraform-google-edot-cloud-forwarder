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

terraform {
  required_version = ">= 1.9.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.0.0"
    }
    # tflint-ignore: terraform_unused_required_providers
    docker = {
      source  = "kreuzwerker/docker"
      version = ">= 3.0"
      # Used by artifact-registry submodule, we keep it here so terraform
      # docs can declare this provider as required.
    }
  }
}
