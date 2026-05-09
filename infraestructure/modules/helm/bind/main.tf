resource "kubernetes_namespace" "bind" {
  metadata {
    name = "bind"
  }
}

locals {
  bind_tsig_include_conf = <<-EOT
    key "${var.bind_tsig_key_name}" {
      algorithm ${var.bind_tsig_algorithm};
      secret "${var.bind_tsig_secret}";
    };
  EOT

  bind_named_conf = <<-EOT
    options {
      directory "/var/cache/bind";
      listen-on port 53 { any; };
      listen-on-v6 { any; };
      allow-query { any; };
      recursion no;
      dnssec-validation no;
    };

    include "/etc/bind/tsig-keys/tsig.conf";

    zone "${var.bind_zone}" IN {
      type master;
      file "/etc/bind/zones/db.${var.bind_zone}";
      update-policy {
        grant ${var.bind_tsig_key_name} zonesub ANY;
      };
      allow-transfer { none; };
    };
  EOT

  bind_zone_file = <<-EOT
    $TTL 60
    @   IN SOA ns1.${var.bind_zone}. admin.${var.bind_zone}. (
          2026050801 ; serial
          60         ; refresh
          60         ; retry
          1209600    ; expire
          60 )       ; minimum
    @       IN NS    ns1.${var.bind_zone}.
    ns1     IN A     127.0.0.1
  EOT
}

resource "kubernetes_secret" "bind_tsig" {
  metadata {
    name      = "bind-tsig"
    namespace = kubernetes_namespace.bind.metadata[0].name
  }

  data = {
    "tsig.conf" = local.bind_tsig_include_conf
  }

  type = "Opaque"
}

resource "kubernetes_config_map" "bind_config" {
  metadata {
    name      = "bind-config"
    namespace = kubernetes_namespace.bind.metadata[0].name
  }

  data = {
    "named.conf"          = local.bind_named_conf
    "db.${var.bind_zone}" = local.bind_zone_file
  }
}

resource "kubernetes_deployment" "bind" {
  metadata {
    name      = "bind9"
    namespace = kubernetes_namespace.bind.metadata[0].name
    labels = {
      app = "bind9"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "bind9"
      }
    }

    template {
      metadata {
        labels = {
          app = "bind9"
        }
      }

      spec {
        init_container {
          name    = "init-zones"
          image   = "busybox:1.36"
          command = ["sh", "-c", "cp /seed/db.${var.bind_zone} /zones/db.${var.bind_zone} && chmod 0644 /zones/db.${var.bind_zone}"]

          volume_mount {
            name       = "bind-config"
            mount_path = "/seed"
            read_only  = true
          }

          volume_mount {
            name       = "bind-zones"
            mount_path = "/zones"
          }
        }

        container {
          name  = "bind9"
          image = "internetsystemsconsortium/bind9:9.18"
          args  = ["-g", "-c", "/etc/bind/named.conf"]

          port {
            container_port = 53
            name           = "dns-udp"
            protocol       = "UDP"
          }

          port {
            container_port = 53
            name           = "dns-tcp"
            protocol       = "TCP"
          }

          volume_mount {
            name       = "bind-config"
            mount_path = "/etc/bind/named.conf"
            sub_path   = "named.conf"
          }

          volume_mount {
            name       = "bind-zones"
            mount_path = "/etc/bind/zones"
          }

          volume_mount {
            name       = "bind-tsig"
            mount_path = "/etc/bind/tsig-keys"
            read_only  = true
          }
        }

        volume {
          name = "bind-config"
          config_map {
            name = kubernetes_config_map.bind_config.metadata[0].name
          }
        }

        volume {
          name = "bind-zones"
          empty_dir {}
        }

        volume {
          name = "bind-tsig"
          secret {
            secret_name = kubernetes_secret.bind_tsig.metadata[0].name
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      spec[0].template[0].metadata[0].annotations,
    ]
  }
}

resource "kubernetes_service" "bind" {
  metadata {
    name      = "bind-dns"
    namespace = kubernetes_namespace.bind.metadata[0].name
  }

  spec {
    selector = {
      app = "bind9"
    }

    port {
      name        = "dns-udp"
      port        = 53
      target_port = 53
      protocol    = "UDP"
    }

    port {
      name        = "dns-tcp"
      port        = 53
      target_port = 53
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}
