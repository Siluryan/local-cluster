output "cluster_id" {
  value = module.oke.cluster_id
}

output "cluster_endpoints" {
  value = module.oke.cluster_endpoints
}

output "vcn_id" {
  value = module.oke.vcn_id
}

output "ssh_to_bastion" {
  value = module.oke.ssh_to_bastion
}

output "ssh_to_operator" {
  value = module.oke.ssh_to_operator
}

output "cluster_kubeconfig" {
  value     = module.oke.cluster_kubeconfig
  sensitive = true
}
