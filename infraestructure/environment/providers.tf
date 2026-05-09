provider "oci" {
  auth         = "ApiKey"
  tenancy_ocid = var.tenancy_id
  user_ocid    = var.user_id
  fingerprint  = var.api_fingerprint
  private_key  = file(pathexpand(var.api_private_key_path))
  region       = var.region
}

provider "kubernetes" {
  host                   = local.k8s_host
  cluster_ca_certificate = local.k8s_ca_pem

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "oci"
    args = [
      "ce", "cluster", "create-kubeconfig",
      "--cluster-id", local.oke_cluster_id,
      "--file", "-",
      "--token-version", "2.0.0",
      "--kube-endpoint", var.oke_kubernetes_endpoint,
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = local.k8s_host
    cluster_ca_certificate = local.k8s_ca_pem

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "oci"
      args = [
        "ce", "cluster", "create-kubeconfig",
        "--cluster-id", local.oke_cluster_id,
        "--file", "-",
        "--token-version", "2.0.0",
        "--kube-endpoint", var.oke_kubernetes_endpoint,
      ]
    }
  }
}
