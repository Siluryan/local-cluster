provider "oci" {
  auth         = "ApiKey"
  tenancy_ocid = var.tenancy_id
  user_ocid    = var.user_id
  fingerprint  = var.api_fingerprint
  private_key  = file(pathexpand(var.api_private_key_path))
  region       = var.region
}
