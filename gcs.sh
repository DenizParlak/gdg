#!/usr/bin/env bash

cwd_path=${PWD_PATH:=$(pwd)}
csv_dir_path="$cwd_path/csv"

echo $cwd_path
echo $csv_dir_path

has_error=false
require_env_variables=("GOOGLE_CLOUD_EMAIL" "GOOGLE_CLOUD_KEY_FILE_NAME" "GOOGLE_CLOUD_PROJECT_ID" "GOOGLE_CLOUD_BUCKET")
for i in "${!require_env_variables[@]}"; do
  require_env_variable_name=${require_env_variables[$i]}
  require_env_variable_value=${!require_env_variables[$i]}

  if [ -z "$require_env_variable_value" ]; then
    echo "error: please provide $require_env_variable_name!"
    has_error=true
  fi
done

if [ $has_error == true ]; then
  exit 1
fi

echo "Script Name: Import Google CLoud Storage"
echo "CWD_PATH: $cwd_path"
echo "CSV_DIR_PATH: $csv_dir_path"
echo "GOOGLE_CLOUD_EMAIL: $GOOGLE_CLOUD_EMAIL"
echo "GOOGLE_CLOUD_PROJECT_ID: $GOOGLE_CLOUD_PROJECT_ID"
echo "GOOGLE_CLOUD_BUCKET: $GOOGLE_CLOUD_BUCKET"
echo "GOOGLE_CLOUD_KEY_FILE_NAME: $GOOGLE_CLOUD_KEY_FILE_NAME"
echo ""

if [[ "$OSTYPE" == "darwin"* ]]; then
  brew install python@3.8
  brew cask install google-cloud-sdk
fi

# Install required packages if not installed
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  apt-get update && apt-get install curl python3.8 gnupg -y

  # Skip gcloud installation if already installed
  if ! [ "$(command -v "gcloud")" ]; then
    # Remove Cloud SDK package resource
    rm -f /etc/apt/sources.list.d/google-cloud-sdk.list

    # Add the Cloud SDK distribution URI as a package resource.
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

    # Import the Google public key
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

    # Update the package repository
    apt-get update

    # Install the Cloud SDK
    DEBIAN_FRONTEND=noninteractive apt-get install google-cloud-sdk -y
  fi
fi

echo "info: show gcloud info"
gcloud info

echo "info: authorizing with a google service account"
gcloud auth activate-service-account "$GOOGLE_CLOUD_EMAIL" --key-file="${cwd_path}/${GOOGLE_CLOUD_KEY_FILE_NAME}"

echo "info: list google service accounts"
gcloud auth list

echo "info: setting up the google service account"
gcloud config set account "$GOOGLE_CLOUD_EMAIL"

gsutil cp -r /data-volume/data_files/csv gs://${GOOGLE_CLOUD_BUCKET}/
