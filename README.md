gcloud # 🚀 GCP Project Bootstrap & Terraform Automation

This repository automates the creation and management of **Google Cloud projects** and resources **Google Cloud Functions**, **Load Balancer**, **Service Accounts**, and **secure IAM setup**.using Bash scripts and Terraform.

---

## 📁 Structure

```
├── scripts/
│   ├── bootstrap.sh             # Script to create GCP project and write to terraform.tfvars
│   └── destroy.sh               # Script to destroy all Terraform resources and optionally delete the GCP project
├── terraform/
│   ├── main.tf                  # Main Terraform entrypoint that uses modules
│   ├── variables.tf             # Input variable definitions
│   ├── terraform.tfvars         # Auto-populated with values (e.g., project_id)
│   └── versions.tf              # Terraform and provider versions
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── output.tf
│   ├── cloud_function/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── output.tf
│   ├── service_account/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── output.tf
│   ├── iam/
│   │   ├── main.tf              # IAM bindings (e.g., add invoker role to service account)
│   │   ├── variables.tf
│   │   └── output.tf
│   ├── load_balancer/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── output.tf
├── cloud_function/
│   ├── main.py                  # Python entrypoint for the Cloud Function
│   └── function-source.zip      # Zipped source code for deployment
```

---

## ⚙️ Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads)
- [gcloud CLI](https://cloud.google.com/sdk/docs/install)
- A GCP billing account
- A GCP service account with appropriate permissions
- Enable APIs like:
  - Cloud Resource Manager
  - IAM
  - Cloud Functions
  - Cloud Run
  - VPC Access
  - Cloud Build
  - Artifact Registry
- ### 🧰 Create GCS Bucket for Terraform Backend (First-Time ONLY)

Create a GCS bucket manually (once per project) to store the Terraform state:

```
gsutil mb -l us-central1 gs://<your-unique-bucket-name>

```

>⚠️ Required once per project. Terraform cannot create its own backend bucket.

---

## 🔐 Permissions Required

Make sure your service account/user has:
- `resourcemanager.projects.create`
- `billing.resourceAssociations.create`
- `serviceusage.services.enable`
- IAM role changes
- VPC access management
---

## 🧾 Naming Conventions

To ensure consistency, clarity, and compatibility with GCP resource constraints, this project follows the naming conventions below:

### ✅ General Rules
- All resource names use **lowercase alphanumeric characters** and hyphens (`-`)
- Avoid underscores (`_`) and uppercase letters
- Keep names concise yet descriptive
- Avoid exceeding GCP-imposed name length limits (e.g., 25 characters for some resources)

### 🏗️ Structure

Most resource names follow this pattern:

```
<env>-<project_name>-<resource_type>
```

| Variable        | Example Value       | Notes |
|----------------|---------------------|-------|
| `env`          | `dev`               | Environment name (e.g., dev, prod) |
| `project_name` | `mounika-test`      | Short, lowercase, hyphenated name |
| `resource_type`| `sa`, `subnet`, `connector` | Resource-specific suffix |

Examples:
- `dev-mounika-test-sa` – Service Account
- `dev-mounika-test-subnet` – VPC Subnet
- `dev-mounika-conn` – VPC Access Connector (shortened due to GCP 25-char limit)

### ⚠️ Special Cases

Some GCP resources (like **VPC Access Connectors**) have strict naming limits or patterns:

- **Connector name**: Must match `^[a-z][-a-z0-9]{0,23}[a-z0-9]$`
- Max 25 characters
- Must start with a letter, end with a letter or number

If your combined name is too long, it's automatically shortened using logic like:

```hcl
connector_name = "${var.env}-${substr(var.project_name, 0, 10)}-conn"
```

### 📌 Pro Tip
Use short but meaningful values for `project_name` and `env` to keep resource names under limit.

---

## 📥 Clone the repo
```
git clone https://github.com/RaniMounikaKotakadi/gcp.git

```
---
## 🪄 Setup

### 1. Edit in `versions.tf` (for First time only per Project)

Edit `terraform/versions.tf`:

```hcl
  backend "gcs" {
    bucket  = "<Bucket-name>"  # Must be created manually beforehand
    prefix  = "gcp-cloud-function/state"          # Folder path inside the bucket
  }

```
🔁 This is needed only once. Replace <your-unique-bucket-name> accordingly. (Already created at begining)

### 2. Fill in `terraform.tfvars`

- naming pattern: <project_name>-<random_suffix> (e.g., mounika-dev-3xk8zy).
- follow as following.
Edit `terraform/terraform.tfvars`:

```hcl
project_name     = "<project_name_lowercase>"
billing_account  = "YOUR-BILLING-ACCOUNT-ID"
region           = "<region>"
```

> 💡 Do **not** set `project_id` manually — it will be auto-managed by the script.

---

### 3. Bootstrap Project & Enable APIs

```bash
./scripts/bootstrap.sh

```

🔧 What it does:
- Checks if a project with the given name exists
- If not, creates a new project with a random suffix (e.g., `project_name_lowercase-ab12cd`)
- Links it to billing
- Enables all required APIs (Cloud Run, VPC Access, Cloud Build, etc.)
- Updates `terraform.tfvars` with the correct `project_id`
- Initializes and applies Terraform configuration to provision infrastructure

✅ This script fully automates environment bootstrapping and resource provisioning.

ℹ️ **Expect that VPC Connector will take time to create**

---

## 🌐 4. Access Your Application

After deployment, the output will include a **Load Balancer IP**.

```hcl
load_balancer_ip = "34.xxx.xxx.xxx"
```

🔗 **Visit in browser**:

```
https://<load_balancer_ip>
```

💬 You’ll see:

```
Hello World
```
 ⚠️ Works only if `is_public = true` 
 
 🔑 For private setups, use a signed identity token with `curl`

 ℹ️ If any error are found like page not found, please wait for 5 mins and try again.

 ℹ️ I observerd delay in  showing _`Hello, World!`_. This might be due to  delayed propagation or Cloud Function cold start latency.

---

## 🧨 Destroy and 🧹 Clean Up

```bash
./scripts/destroy.sh
```

🗑️ What it does:
- Destroys Terraform-managed resources
- Optionally deletes the GCP project itself
- Prompts whether to delete the GCP project itself (default: **No**)
- Type in **y** when promted to delete project as well.

---

## ✅ What It Manages

- GCP Project & Billing Link
- Cloud Function (v2)
- VPC & Subnet
- VPC Access Connector
- Load Balancer (HTTP)
- Service Accounts
- Storage Bucket for source code

---

## 🧠 Notes

- Repeated `bootstrap.sh` runs will **reuse** existing projects if name matches.
- Conflicts are avoided using random suffixes for project IDs.
- Ensure your user or service account has permission to create projects and link billing accounts.

---

## 📌 TODO / Improvements

- Optional support for Org folders
- Module-specific destroy (e.g., function-only)
- Logging and error reporting enhancements
- Toggle for is_public and public_member
    - In a “Custom Access”(terraform.tfvars) section:

           
            is_public     = true
            public_member = "allUsers"
            
                        or
          
            is_public     = true
            public_member = "serviceAccount:internal-sa@project.iam.gserviceaccount.com"

- 🔐 Security Consideration: Public vs Private Access

    - This deployment uses a Cloud Function (Gen2) behind a Load Balancer via a Serverless NEG.

    - The Cloud Function is exposed publicly via:
        ```
        roles/run.invoker → allUsers
        ```
    - This ensures the HTTP(S) Load Balancer can route unauthenticated traffic to the function and return a valid response.

- 🔒 Why Private Access Didn’t Work

    - Attempting to bind `roles/run.invoker` to a custom service account (like `lb-invoker@...`) fails because:

    - Serverless NEGs **do not authenticate** traffic by default
    - The Load Balancer makes unauthenticated HTTP calls to Cloud Run (Gen2)
    - So **Cloud Run denies the request** unless `allUsers` is explicitly allowed
---

### 🧠 In Production

For a secure production deployment, you should:

- Remove `allUsers` from the IAM policy
- Use an **HTTPS Load Balancer + IAP** (Identity-Aware Proxy)
- Or use a Cloud Run client (not NEG) that can pass a signed identity token

This keeps the endpoint private and auditable.

---

### ✅ Summary

| Use Case       | IAM Setting               | Works? |
|----------------|---------------------------|--------|
| Interview demo | `allUsers` + `run.invoker`| ✅ Yes |
| Secure prod    | IAP or signed token auth  | ✅ Yes |
| SA-only access | Not supported via NEG     | ❌ No  |

---

## 📞 Support

Feel free to open an issue or reach out if you'd like help with customizing modules or automating even further.

---

 ℹ️ **scripts are run and tested on Windows gitbash**
