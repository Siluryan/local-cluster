locals {
  oke_cluster_id = coalesce(
    (var.oke_cluster_id != null && var.oke_cluster_id != "") ? var.oke_cluster_id : null,
    try(data.terraform_remote_state.cluster.outputs.cluster_id, null)
  )

  kubeconfig_yaml = yamldecode(data.oci_containerengine_cluster_kube_config.oke.content)
  kube_cluster      = local.kubeconfig_yaml.clusters[0].cluster

  k8s_host   = local.kube_cluster.server
  k8s_ca_pem = base64decode(local.kube_cluster["certificate-authority-data"])
}
