# === Set These Variables ===
$ProjectId = "your-project-id"
$OrgId = "your-org-id"
$BillingAccount = "your-billing-account-id"

Write-Host "🔍 Checking if GCP project '$ProjectId' exists..."
$existingProject = & gcloud projects list --filter="projectId=$ProjectId" --format="value(projectId)"

if ([string]::IsNullOrWhiteSpace($existingProject)) {
    Write-Host "✅ Project does not exist. Creating..."

    & gcloud projects create $ProjectId --organization=$OrgId

    Write-Host "🔗 Linking billing account..."
    & gcloud beta billing projects link $ProjectId --billing-account=$BillingAccount

    Write-Host "⚙️ Enabling required services..."
    & gcloud services enable `
        compute.googleapis.com `
        cloudfunctions.googleapis.com `
        iam.googleapis.com `
        cloudresourcemanager.googleapis.com `
        --project=$ProjectId
}
else {
    Write-Host "✅ Project '$ProjectId' already exists. Proceeding to deploy..."
}

# === (Optional) Authenticate if not already done ===
Write-Host "🔐 Logging in if needed..."
& gcloud auth application-default login

# === Terraform Deploy ===
Write-Host "🚀 Running Terraform..."
& terraform init
& terraform apply -auto-approve -var="project_id=$ProjectId"
