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
    sed -i "/^$key[[:space:]]*=/d" "$TFVARS_PATH"
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
PROJECT_NAME=$(get_var "project_name")
BILLING_ACCOUNT=$(get_var "billing_account")

if [ -z "$PROJECT_NAME" ] || [ -z "$BILLING_ACCOUNT" ]; then
    echo "❌ 'project_name' or 'billing_account' missing in $TFVARS_PATH"
    exit 1
fi

# === Check for existing project ===
echo "🔍 Checking if GCP project named '$PROJECT_NAME' exists..."
EXISTING_PROJECT_ID=$(gcloud projects list --filter="name:$PROJECT_NAME" --format="value(projectId)" | head -n1)

if [ -n "$EXISTING_PROJECT_ID" ]; then
    echo "✅ Found existing project: $EXISTING_PROJECT_ID"
    set_tfvar "project_id" "$EXISTING_PROJECT_ID"
    export TF_VAR_project_id="$EXISTING_PROJECT_ID"
else
    echo "🆕 Project not found. Creating new one..."
    RANDOM_SUFFIX=$(LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | head -c 6)
    NEW_PROJECT_ID="${PROJECT_NAME}-${RANDOM_SUFFIX}"
    echo "📌 New Project ID: $NEW_PROJECT_ID"

    gcloud projects create "$NEW_PROJECT_ID" --name="$PROJECT_NAME" --quiet

    echo "⏳ Waiting for project '$NEW_PROJECT_ID' to be fully available..."
    until gcloud projects describe "$NEW_PROJECT_ID" &> /dev/null; do
        sleep 3
    done

    echo "🔗 Linking billing account..."
    if ! gcloud beta billing projects link "$NEW_PROJECT_ID" --billing-account="$BILLING_ACCOUNT"; then
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
        enable_api_if_needed "$api" "$NEW_PROJECT_ID"
    done

    # 🧹 Remove any old 'project_id' before writing the new one
    sed -i.bak '/^project_id *=/d' "$TFVARS_PATH"
    
    # Save to tfvars
    set_tfvar "project_id" "$NEW_PROJECT_ID"
    export TF_VAR_project_id="$NEW_PROJECT_ID"
fi

# === Run Terraform ===
echo "🚀 Running Terraform apply"
cd "$TF_DIR" || exit 1
terraform init -input=false
terraform apply -auto-approve
