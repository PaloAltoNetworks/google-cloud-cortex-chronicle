#!/bin/bash -eu
#
# Uninstall script for Cloud Run Job and associated resources

# Check if the env.properties file exists
if [ ! -f env.properties ]; then
    echo "Error: env.properties file not found."
    exit 1
fi

# Export variables from env.properties
export $(grep -v '^#' env.properties | xargs)

echo "Environment variables loaded successfully."

# Check if the Cloud Run Job exists and delete it
if gcloud run jobs describe ${JOB_NAME} --region=${REGION} >/dev/null 2>&1; then
  echo "Deleting Cloud Run Job '${JOB_NAME}'..."
  gcloud run jobs delete ${JOB_NAME} --region=${REGION} --quiet
else
  echo "Cloud Run Job '${JOB_NAME}' does not exist."
fi

# Check if the Cloud Scheduler trigger exists and delete it
if gcloud scheduler jobs describe ${JOB_NAME}-trigger --location=${REGION} >/dev/null 2>&1; then
  echo "Deleting Cloud Scheduler Trigger '${JOB_NAME}-trigger}'..."
  gcloud scheduler jobs delete ${JOB_NAME}-trigger --location=${REGION} --quiet
else
  echo "Cloud Scheduler Trigger '${JOB_NAME}-trigger}' does not exist."
fi

# Check if the Docker image exists in Artifact Registry and delete it
if gcloud artifacts docker images list $REGION-docker.pkg.dev/$GCP_PROJECT_ID/$REPO_NAME --filter="IMAGE=$IMAGE_NAME" --format="value(NAME)" >/dev/null 2>&1; then
  echo "Deleting Docker image '${IMAGE_NAME}' from Artifact Registry..."
  gcloud artifacts docker images delete $REGION-docker.pkg.dev/$GCP_PROJECT_ID/$REPO_NAME/$IMAGE_NAME --quiet
else
  echo "Docker image '${IMAGE_NAME}' does not exist in Artifact Registry."
fi

# Check if the Artifact Registry repository exists and delete it
if gcloud artifacts repositories describe ${REPO_NAME} --location=${REGION} >/dev/null 2>&1; then
  echo "Deleting Artifact Registry repository '${REPO_NAME}'..."
  gcloud artifacts repositories delete ${REPO_NAME} --location=${REGION} --quiet
else
  echo "Artifact Registry repository '${REPO_NAME}' does not exist."
fi

echo "Uninstallation completed successfully."
