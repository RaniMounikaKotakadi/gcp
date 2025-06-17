#!/bin/bash

# === Paths ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$SCRIPT_DIR/../terraform"
TFVARS_PATH="$TF_DIR/terraform.tfvars"

# === Functions ===
get_var() {
    grep -i "^$1" "$TFVARS_PATH" 2>/dev/null | sed 's/\r//' | awk -F '=' '{print $2}' | tr -d '" '
}

set_tfvar() {
    local key=$1
    local value=$2
    sed -i.bak "/^$key[[:space:]]*=/d" "$TFVARS_PATH"
    echo "$key = \"$value\"" >> "$TFVARS_PATH"
}

enable_api_if_needed() {
    local api=$1
    local project=$2
    if ! gcloud services list --enabled --project "$project" --format="value(config.name)" | grep -q "^$api$"; then
        echo "⚙️ Enabling API: $api"
        gcloud services enable "$api" --project "$project"
    else
        echo "✅ API already enabled: $api"
    fi
}

# === Load variables ===
PROJECT_BASE=$(get_var "project_name")
ENV=$(get_var "env")
BILLING_ACCOUNT=$(get_var "billing_account")

if [ -z "$PROJECT_BASE" ] || [ -z "$ENV" ] || [ -z "$BILLING_ACCOUNT" ]; then
    echo "❌ 'project_name', 'env', or 'billing_account' missing in $TFVARS_PATH"
    exit 1
fi

PROJECT_NAME="${ENV}-${PROJECT_BASE}"

echo "🔍 Checking if GCP project named '$PROJECT_NAME' exists..."
EXISTING_PROJECT_ID=$(gcloud projects list --filter="name:$PROJECT_NAME" --format="value(projectId)" | head -n1)

if [ -n "$EXISTING_PROJECT_ID" ]; then
    echo "✅ Found existing project: $EXISTING_PROJECT_ID"
else
    echo "🆕 Project not found. Creating new one..."
    RANDOM_SUFFIX=$(LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | head -c 6)
    EXISTING_PROJECT_ID="${ENV}-${PROJECT_BASE}-${RANDOM_SUFFIX}"
    echo "📌 New Project ID: $EXISTING_PROJECT_ID"

    gcloud projects create "$EXISTING_PROJECT_ID" --name="$PROJECT_NAME" --quiet

    echo "⏳ Waiting for project '$EXISTING_PROJECT_ID' to be fully available..."
    until gcloud projects describe "$EXISTING_PROJECT_ID" &> /dev/null; do
        sleep 3
    done

    echo "🔗 Linking billing account..."
    if ! gcloud beta billing projects link "$EXISTING_PROJECT_ID" --billing-account="$BILLING_ACCOUNT"; then
        echo "❌ Billing account link failed. Exiting."
        exit 1
    fi

    echo "⚙️ Enabling required APIs..."
    REQUIRED_APIS=(
        cloudresourcemanager.googleapis.com
        cloudbilling.googleapis.com
        compute.googleapis.com
        iam.googleapis.com
        cloudfunctions.googleapis.com
        artifactregistry.googleapis.com
        vpcaccess.googleapis.com
        cloudbuild.googleapis.com
        run.googleapis.com
    )

    for api in "${REQUIRED_APIS[@]}"; do
        enable_api_if_needed "$api" "$EXISTING_PROJECT_ID"
    done
fi

# Save and apply project ID
set_tfvar "project_id" "$EXISTING_PROJECT_ID"
export TF_VAR_project_id="$EXISTING_PROJECT_ID"

echo "🔧 Setting gcloud active project to $EXISTING_PROJECT_ID"
gcloud config set project "$EXISTING_PROJECT_ID"
gcloud auth application-default set-quota-project "$EXISTING_PROJECT_ID"

# === Confirm final project ID and gcloud config ===
echo "✅ Terraform will use project ID: $TF_VAR_project_id"
gcloud config get-value project

# === Run Terraform ===
echo "🚀 Running Terraform apply"
cd "$TF_DIR" || exit 1
terraform init -input=false
terraform apply -auto-approve
