variable "tenancy_id" {
  type = string
}

variable "user_id" {
  type = string
}

variable "api_fingerprint" {
  type = string
}

variable "api_private_key_path" {
  type = string
}

variable "region" {
  type = string
}

variable "home_region" {
  type    = string
  default = null
}

variable "compartment_id" {
  type = string
}

variable "ssh_public_key_path" {
  type = string
}
