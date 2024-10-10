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


# Check if the env.properties file exists
if [ ! -f env.properties ]; then
    echo "Error: env.properties file not found."
    exit 1
fi

# Export variables from env.properties
export $(grep -v '^#' env.properties | xargs)

echo "Environment variables loaded successfully."

gcloud config set project $GCP_PROJECT_ID
  
# create the artifact registry repository before running following commands.
gcloud artifacts repositories describe ${REPO_NAME} \
  --location=${REGION} \
  --format="value(name)" || \
gcloud artifacts repositories create ${REPO_NAME} \
  --repository-format=DOCKER \
  --location=${REGION}
    
    
gcloud auth configure-docker \
    $REGION-docker.pkg.dev

docker build -t $IMAGE_NAME .
docker tag $IMAGE_NAME:latest $REGION-docker.pkg.dev/$GCP_PROJECT_ID/$REPO_NAME/$IMAGE_NAME:latest
docker push $REGION-docker.pkg.dev/$GCP_PROJECT_ID/$REPO_NAME/$IMAGE_NAME


# Check if the job already exists
if gcloud run jobs describe ${JOB_NAME} --region=${REGION} >/dev/null 2>&1; then
  echo "Cloud Run Job '${JOB_NAME}' already exists. Updating..."
  gcloud run jobs update ${JOB_NAME} --image $REGION-docker.pkg.dev/$GCP_PROJECT_ID/$REPO_NAME/$IMAGE_NAME:latest --region=${REGION}
else
  # Create the Cloud Run Job
  gcloud run jobs deploy ${JOB_NAME} --image $REGION-docker.pkg.dev/$GCP_PROJECT_ID/$REPO_NAME/$IMAGE_NAME:latest --tasks 1 --parallelism 1 --region=${REGION} --set-env-vars SRC_BUCKET=$SRC_BUCKET,DEST_BUCKET=$DEST_BUCKET,SECRET_NAME=$SECRET_NAME,GCP_PROJECT_ID=$GCP_PROJECT_ID
fi

# Check if the trigger already exists
if gcloud scheduler jobs describe ${JOB_NAME}-trigger --location=${REGION} >/dev/null 2>&1; then
  echo "Cloud Scheduler Trigger '${JOB_NAME}-trigger' already exists. Updating..."
  gcloud scheduler jobs update http ${JOB_NAME}-trigger \
    --location $REGION \
    --schedule="*/$JOB_SCHEDULE_MINS * * * *"
else
  # Add a Cloud Scheduler trigger
  gcloud scheduler jobs create http ${JOB_NAME}-trigger \
    --location $REGION \
    --schedule="*/$JOB_SCHEDULE_MINS * * * *" \
    --uri="https://${REGION}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/$GCP_PROJECT_ID/jobs/$JOB_NAME:run" \
    --http-method POST \
    --oauth-service-account-email $PROJECT_NUMBER-compute@developer.gserviceaccount.com  


fi

# Get the job's service account
JOB_SA=$(gcloud run jobs describe ${JOB_NAME} --region=${REGION} | grep "Service account" | cut -d ":" -f2 | tr -d " ")

echo "Cloud Run Job is set up with the following service account: ${JOB_SA}"
echo "Please grant this service account Secret Manager Secret Accessor permissions to access secrets."

