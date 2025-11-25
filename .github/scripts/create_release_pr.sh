#!/bin/bash
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

set -euo pipefail

BRANCH_NAME="new-release"
BASE_BRANCH="main"

echo "Preparing $BASE_BRANCH and running changelog update..."
git checkout "$BASE_BRANCH"
git pull origin "$BASE_BRANCH"
make chlog-update

echo "Switching to branch $BRANCH_NAME..."
git checkout -B "$BRANCH_NAME"

echo "Committing and pushing changes..."
git add .

if git diff --staged --quiet; then
  echo "No changes to commit. Nothing new to release. Exiting."
  exit 0
fi

git commit -m "Update changelog."
git push origin "$BRANCH_NAME" --force

echo "Creating or updating PR..."
if ! gh pr create \
  --title="Release new version of ECF GCP Terraform module" \
  --base "$BASE_BRANCH" \
  --head "$BRANCH_NAME" \
  --body="This PR releases a new version of ECF GCP Terraform module, by updating the changelog and removing old changelog fragments."; then
    echo "PR already exists. Force-push updated its content."
else
    echo "New PR created."
fi

echo "Done."