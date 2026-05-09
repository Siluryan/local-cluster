data "terraform_remote_state" "cluster" {
  backend = "oci"
  config = {
    bucket              = var.terraform_state_bucket
    key                 = var.terraform_state_cluster_key
    namespace           = var.terraform_state_namespace
    region              = var.terraform_state_region
    auth                = "APIKey"
    config_file_profile = "DEFAULT"
  }
}
