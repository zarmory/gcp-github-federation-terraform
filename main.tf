provider "google" {
  project = var.gcp_project_id
}

# Enable baseline APIs - we need this for bootstrap
# You can NOT enable these through the usual google_project_service resource when
# working on a freshly created projects
module "project_services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 14.4"

  project_id = var.gcp_project_id

  activate_apis = [
    "serviceusage.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com"
  ]
}

# Our state bucket
resource "google_storage_bucket" "state" {
  name                     = "iac-${var.gcp_project_id}"
  force_destroy            = false
  location                 = var.state_bucket_location
  storage_class            = "STANDARD"
  public_access_prevention = "enforced"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      days_since_noncurrent_time = var.state_delete_after_days
    }
  }

}

# Service account to operate under
resource "google_service_account" "terraform" {
  account_id   = "terraform"
  display_name = "Terraform Service Account"
}

# Terraform can do everything in this project
resource "google_project_iam_member" "terraform" {
  project = var.gcp_project_id
  role    = "roles/owner"
  member  = google_service_account.terraform.member
}

# Allow project admins to impersonate
resource "google_service_account_iam_binding" "terraform_token_creator" {
  service_account_id = google_service_account.terraform.name
  role               = "roles/iam.serviceAccountTokenCreator"

  members = var.project_admins
}

# Federation for GitHub Actions

resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github"
  description               = "Workload Identity Pool managed by Terraform"
}

resource "google_iam_workload_identity_pool_provider" "gh_actions" {
  attribute_mapping = {
    "attribute.actor"      = "assertion.actor"
    "attribute.aud"        = "assertion.aud"
    "attribute.repository" = "assertion.repository"
    "google.subject"       = "assertion.sub"
  }
  description                        = "Workload Identity Pool Provider managed by Terraform"
  workload_identity_pool_provider_id = "gh-actions"
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id

  oidc {
    allowed_audiences = []
    issuer_uri        = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_binding" "terraform_workload_identity_user" {
  service_account_id = google_service_account.terraform.name

  role = "roles/iam.workloadIdentityUser"

  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repository}",
  ]
}
