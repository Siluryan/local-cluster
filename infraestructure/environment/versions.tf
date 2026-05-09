terraform {
  required_version = ">= 1.12.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.0.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 3.0.0"
    }
    oci = {
      source  = "oracle/oci"
      version = ">= 8.2.0"
    }
  }
}
