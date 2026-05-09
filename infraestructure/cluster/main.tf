module "oke" {
  source = "../modules/oke"

  providers = {
    oci      = oci
    oci.home = oci.home
  }

  compartment_id      = var.compartment_id
  ssh_public_key_path = pathexpand(var.ssh_public_key_path)

  bastion_availability_domain  = local.preferred_ad_name
  operator_availability_domain = local.preferred_ad_name

  create_cluster     = true
  cluster_name       = "oke-cluster"
  kubernetes_version = "v1.34.2"

  worker_pool_mode = "node-pool"
  worker_pool_size = 1

  worker_pools = {
    np1 = merge(
      { size = 1 },
      var.availability_domain_number != null ? { placement_ads = [var.availability_domain_number] } : {}
    )
  }

  worker_shape = {
    shape                   = "VM.Standard.A1.Flex"
    ocpus                   = 2
    memory                  = 12
    boot_volume_size        = 50
    boot_volume_vpus_per_gb = 10
  }

  bastion_shape = {
    shape                     = "VM.Standard.A1.Flex"
    ocpus                     = 1
    memory                    = 6
    boot_volume_size          = 50
    baseline_ocpu_utilization = 100
  }

  bastion_image_os         = "Oracle Linux"
  bastion_image_os_version = "8"

  operator_shape = {
    shape                     = "VM.Standard.A1.Flex"
    ocpus                     = 1
    memory                    = 6
    boot_volume_size          = 50
    baseline_ocpu_utilization = 100
  }

  worker_is_public = true

  control_plane_is_public           = true
  assign_public_ip_to_control_plane = true

  load_balancers          = "public"
  preferred_load_balancer = "public"
}
