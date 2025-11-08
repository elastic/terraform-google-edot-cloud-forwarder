#!/usr/bin/env bash

# We need to wait usually tens of seconds until the token becomes valid. 
# Otherwise, token operations on the SA from the current user will fail with permission denied.
# This is expected behavior.

set -euo pipefail

# Fail if IMPERSONATE_SERVICE_ACCOUNT is unset
: "${IMPERSONATE_SERVICE_ACCOUNT:?Environment variable IMPERSONATE_SERVICE_ACCOUNT must be set}"

TIMEOUT=120
WAIT=10
END=$((SECONDS+TIMEOUT))

while (( SECONDS < END )); do
  if ! SUCCESS=$(gcloud auth print-identity-token --impersonate-service-account "$IMPERSONATE_SERVICE_ACCOUNT" 2>/dev/null); then
    echo "Current gcloud user failed to get test ID token to impersonate the SA. Retrying in $WAIT seconds..." >&2
    sleep $WAIT
    continue
  else
    echo "Current gcloud user successfully got test ID token to impersonate the SA."
    exit 0
  fi
done

echo "Current gcloud user failed to get test ID token to impersonate SA ${IMPERSONATE_SERVICE_ACCOUNT} after ${TIMEOUT}s." >&2
exit 1