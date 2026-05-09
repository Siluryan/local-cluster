terraform {
  backend "oci" {
    bucket              = "siluryan-local-cluster"
    namespace           = "idpeegudu7ut"
    key                 = "infraestructure/cluster/terraform.tfstate"
    region              = "us-ashburn-1"
    auth                = "APIKey"
    config_file_profile = "DEFAULT"
  }
}
