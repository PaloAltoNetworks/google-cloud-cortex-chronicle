#!/bin/bash -eu
#
# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Function to print usage
usage() {
    echo "Usage: $0 GCP_PROJECT_ID SRC_BUCKET DEST_BUCKET SECRET_NAME"
    exit 1
}

# Check if all environment variables are set
if [ -z "$GCP_PROJECT_ID" ] || [ -z "$SRC_BUCKET" ] || [ -z "$DEST_BUCKET" ] || [ -z "$SECRET_NAME" ]; then
    echo "Error: Missing environment variables."
    usage
fi

echo "Batch process started."

# Record the start time
start_time=$(date +%s)

# set project to access the secret
gcloud config set project $GCP_PROJECT_ID
if [ $? -ne 0 ]; then
    echo "Error: Setting up the prject $GCP_PROJECT_ID"
    exit 1
fi

# Fetch the secret and save it to /tmp/key.json
gcloud secrets versions access latest --secret="$SECRET_NAME" --quiet > /tmp/key.json
if [ $? -ne 0 ]; then
    echo "Error: Failed to fetch the secret."
    exit 1
fi

# Activate gcloud with the key
gcloud auth activate-service-account --key-file=/tmp/key.json
if [ $? -ne 0 ]; then
    echo "Error: Failed to activate service account."
    rm -f /tmp/key.json
    exit 1
fi

# Run gcloud rsync command
gcloud storage rsync -r "gs://$SRC_BUCKET" "gs://$DEST_BUCKET"
if [ $? -ne 0 ]; then
    echo "Error: Failed to sync buckets."
    rm -f /tmp/key.json
    exit 1
fi

# Clean up
rm -f /tmp/key.json

# Record the end time
end_time=$(date +%s)
elapsed_time=$((end_time - start_time))

echo "Batch process completed successfully in $elapsed_time seconds."
exit 0
                                                                                                                          34,1          96%    
