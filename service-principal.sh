#!/env/bin bash
set -eou pipefail

# check if PROJECT and SERVICE_ACCOUNT_NAME are set
if [ -z "${PROJECT}" ]; then
    echo "PROJECT env var is not set. Please set it to your GCP project name."
    exit 1
fi

if [ -z "${SERVICE_ACCOUNT_NAME}" ]; then
    echo "SERVICE_ACCOUNT_NAME env var is not set. Please set it to your service account name."
    exit 1
fi

export SERVICE_ACCOUNT_ADDRESS=${SERVICE_ACCOUNT_NAME}@${PROJECT}.iam.gserviceaccount.com

gcloud iam service-accounts create --project ${PROJECT} ${SERVICE_ACCOUNT_NAME}

gcloud projects add-iam-policy-binding ${PROJECT} \
--member serviceAccount:${SERVICE_ACCOUNT_ADDRESS} \
--role roles/lifesciences.workflowsRunner

gcloud projects add-iam-policy-binding ${PROJECT} \
--member serviceAccount:${SERVICE_ACCOUNT_ADDRESS} \
--role roles/iam.serviceAccountUser

gcloud projects add-iam-policy-binding ${PROJECT} \
--member serviceAccount:${SERVICE_ACCOUNT_ADDRESS} \
--role roles/serviceusage.serviceUsageConsumer

gcloud projects add-iam-policy-binding ${PROJECT} \
--member serviceAccount:${SERVICE_ACCOUNT_ADDRESS} \
--role roles/storage.objectAdmin


export SERVICE_ACCOUNT_KEY=${SERVICE_ACCOUNT_NAME}-private-key.json
gcloud iam service-accounts keys create \
--iam-account=${SERVICE_ACCOUNT_ADDRESS} \
--key-file-type=json ${SERVICE_ACCOUNT_KEY}
export SERVICE_ACCOUNT_KEY_FILE=${PWD}/${SERVICE_ACCOUNT_KEY}
export GOOGLE_APPLICATION_CREDENTIALS=${PWD}/${SERVICE_ACCOUNT_KEY}
