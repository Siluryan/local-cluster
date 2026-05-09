variable "tenancy_id" {
  type = string
  validation {
    condition     = length(var.tenancy_id) > 0 && startswith(var.tenancy_id, "ocid1.tenancy.")
    error_message = "tenancy_id must be a non-empty tenancy OCID."
  }
}

variable "user_id" {
  type = string
  validation {
    condition     = length(var.user_id) > 0 && startswith(var.user_id, "ocid1.user.")
    error_message = "user_id must be a non-empty user OCID."
  }
}

variable "api_fingerprint" {
  type = string
  validation {
    condition     = length(var.api_fingerprint) > 0
    error_message = "api_fingerprint must be non-empty."
  }
}

variable "api_private_key_path" {
  type = string
  validation {
    condition     = fileexists(pathexpand(var.api_private_key_path))
    error_message = "api_private_key_path must point to an existing PEM file (use an absolute path if ~ does not resolve as expected)."
  }
}

variable "region" {
  type = string
  validation {
    condition     = length(var.region) > 0
    error_message = "region must be non-empty."
  }
}

variable "compartment_id" {
  type     = string
  default  = null
  nullable = true
}

variable "bucket_name" {
  type    = string
  default = "siluryan-local-cluster"
}
