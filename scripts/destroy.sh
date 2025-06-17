#!/bin/bash

set -e

# === Paths (relative to script) ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$SCRIPT_DIR/../terraform"
TFVARS_PATH="$TF_DIR/terraform.tfvars"

# === Read value from tfvars ===
get_var() {
    grep -i "^$1" "$TFVARS_PATH" 2>/dev/null | sed 's/\r//' | awk -F '=' '{print $2}' | tr -d '" '
}

PROJECT_ID=$(get_var "project_id")

if [ -z "$PROJECT_ID" ]; then
    echo "❌ Error: 'project_id' not found in $TFVARS_PATH"
    exit 1
fi

echo "🧨 Starting Terraform destroy for project: $PROJECT_ID"

cd "$TF_DIR" || { echo "❌ Failed to change directory to $TF_DIR"; exit 1; }

export TF_VAR_project_id="$PROJECT_ID"

terraform init -input=false
terraform destroy -auto-approve

echo
read -p "❓ Do you want to delete the entire GCP project '$PROJECT_ID'? [y/N]: " DELETE_PROJECT
DELETE_PROJECT=${DELETE_PROJECT:-N}

if [[ "$DELETE_PROJECT" =~ ^[Yy]$ ]]; then
    echo "🗑 Deleting GCP project: $PROJECT_ID"
    gcloud projects delete "$PROJECT_ID" --quiet
    echo "✅ Project deleted."
else
    echo "✅ Terraform resources destroyed. GCP project preserved."
fi

