terraform {
  required_version = "~> 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.7"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.7"
    }
  }
}
