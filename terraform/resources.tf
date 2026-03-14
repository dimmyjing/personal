resource "talos_image_factory_schematic" "x86" {
  schematic = yamlencode({
    customization = {
      systemExtensions = {
        officialExtensions = []
      }
    }
  })
}

data "talos_image_factory_urls" "hcloud_amd64" {
  talos_version = var.talos_version
  schematic_id  = talos_image_factory_schematic.x86.id
  platform      = "hcloud"
  architecture  = "amd64"
}

resource "imager_image" "talos_x86" {
  image_url    = data.talos_image_factory_urls.hcloud_amd64.urls.disk_image
  architecture = "x86"
  location     = var.location
  server_type  = var.imager_server_type
  description  = "Talos ${var.talos_version} for Hetzner Cloud"
  labels       = { version = var.talos_version }
}

module "talos" {
  source  = "hcloud-talos/talos/hcloud"
  version = "v3.2.1"

  hcloud_token              = var.hcloud_token
  cluster_name              = var.cluster_name
  cluster_prefix            = true
  cluster_api_host          = var.cluster_api_host
  location_name             = var.location
  kubeconfig_endpoint_mode  = "public_endpoint"
  firewall_kube_api_source  = ["0.0.0.0/0"]
  firewall_talos_api_source = ["0.0.0.0/0"]
  talos_version             = var.talos_version
  control_plane_nodes = [
    for i in range(var.controlplane_count) :
    { id = i + 1, type = var.controlplane_type }
  ]
  control_plane_allow_schedule    = var.allow_scheduling_on_controlplane
  worker_nodes                    = []
  disable_arm                     = true
  disable_x86                     = false
  talos_image_id_x86              = imager_image.talos_x86.id
  kubernetes_version              = var.kubernetes_version
  cilium_version                  = var.cilium_version
  cilium_enable_encryption        = true
  cilium_enable_service_monitors  = false
  deploy_prometheus_operator_crds = false
}

resource "cloudflare_dns_record" "cluster_api" {
  count   = var.controlplane_count
  name    = "kube"
  ttl     = 60
  type    = "A"
  zone_id = var.cloudflare_zone_id
  comment = "DNS record for Kubernetes API"
  content = module.talos.public_ipv4_list[count.index]
  proxied = false
}

resource "local_file" "talosconfig" {
  filename = "../config/talosconfig"
  content  = module.talos.talosconfig
}

resource "local_file" "kubeconfig" {
  filename = "../config/kubeconfig"
  content  = module.talos.kubeconfig
}

resource "kubernetes_namespace_v1" "flux-system" {
  metadata {
    name = "flux-system"
  }
  depends_on = [module.talos.kubeconfig, cloudflare_dns_record.cluster_api]
  lifecycle {
    ignore_changes = all
  }
}

resource "kubernetes_secret_v1" "sops-age" {
  metadata {
    name      = "sops-age"
    namespace = "flux-system"
  }
  data = {
    "age.agekey" = file("${path.root}/../config/key.txt")
  }
  depends_on = [kubernetes_namespace_v1.flux-system]
}

resource "flux_bootstrap_git" "flux" {
  depends_on         = [kubernetes_secret_v1.sops-age]
  embedded_manifests = true
  components_extra   = ["image-reflector-controller", "image-automation-controller"]
  path               = "clusters/hetzner-prod"
}
