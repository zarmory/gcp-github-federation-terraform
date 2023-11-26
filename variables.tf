variable "github_repository" {
  description = "GitHub repository in <org>/<repo> format to allow for Workload Identity"
  type        = string
}

variable "project_admins" {
  description = <<EOT
    IAM members to allow impersonate to the terraform service account.
    Usually it will be a list of `user:<your email>' or group `group:<group admins email'.
    Whatever you specify, make sure it includes your current account, otherwise terraform will fail.
  EOT
  type        = list(string)
}

variable "gcp_project_id" {
  description = "GCP Project ID to run on. By default, it's set by Makefile"
  type        = string
}

variable "state_bucket_location" {
  description = "Location of the GCP bucket for TF state storage"
  type        = string
  default     = "US"
}

variable "state_delete_after_days" {
  description = "Delete NON-CURRENT versions of the state file after the set number of days"
  type        = number
  default     = 1825 # 5 years

}
