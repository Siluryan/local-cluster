data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_id
}

locals {
  # Mesmo esquema que o módulo OKE: último carácter do nome do AD → número (ex. …AD-2 → 2)
  ad_number_to_name = {
    for ad in data.oci_identity_availability_domains.ads.availability_domains :
    parseint(substr(ad.name, -1, -1), 10) => ad.name
  }

  preferred_ad_name = (
    var.availability_domain_number != null ?
    lookup(local.ad_number_to_name, var.availability_domain_number, null) :
    null
  )
}
