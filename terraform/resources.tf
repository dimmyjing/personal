data "talos_image_factory_urls" "hcloud_amd64" {
  talos_version = var.talos_version
  schematic_id  = "376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba"
  platform      = "hcloud"
  architecture  = "amd64"
}

resource "imager_image" "talos_x86" {
  image_url    = data.talos_image_factory_urls.hcloud_amd64.urls.disk_image
  architecture = "x86"
  location     = var.location
  server_type  = var.imager_server_type
  description  = "Talos ${var.talos_version} for Hetzner Cloud"
  labels = {
    version = var.talos_version
  }
}

resource "hcloud_network" "network" {
  name     = var.private_network_name
  ip_range = var.private_network_ip_range
}

resource "hcloud_network_subnet" "subnet" {
  network_id   = hcloud_network.network.id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = var.private_network_subnet_range
}

resource "hcloud_load_balancer" "controlplane_load_balancer" {
  name               = "talos-lb"
  load_balancer_type = var.load_balancer_type
  network_zone       = var.network_zone
}

resource "hcloud_load_balancer_network" "srvnetwork" {
  load_balancer_id = hcloud_load_balancer.controlplane_load_balancer.id
  network_id       = hcloud_network.network.id
}

resource "hcloud_load_balancer_target" "controlplane_target" {
  count            = var.controlplane_count
  type             = "server"
  load_balancer_id = hcloud_load_balancer.controlplane_load_balancer.id
  server_id        = hcloud_server.controlplane_server[count.index].id
  use_private_ip   = true
}

resource "hcloud_load_balancer_service" "controlplane_load_balancer_service_kubectl" {
  load_balancer_id = hcloud_load_balancer.controlplane_load_balancer.id
  protocol         = "tcp"
  listen_port      = 6443
  destination_port = 6443
}

resource "hcloud_load_balancer_service" "controlplane_load_balancer_service_talosctl" {
  load_balancer_id = hcloud_load_balancer.controlplane_load_balancer.id
  protocol         = "tcp"
  listen_port      = 50000
  destination_port = 50000
}

resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version_contract
}

data "talos_machine_configuration" "controlplane" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${hcloud_load_balancer.controlplane_load_balancer.ipv4}:6443"
  machine_type       = "controlplane"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version_contract
  kubernetes_version = var.kubernetes_version
  config_patches = [
    templatefile("${path.module}/patches/controlplane.yaml.tmpl", {
      loadbalancerip  = hcloud_load_balancer.controlplane_load_balancer.ipv4,
      subnet          = var.private_network_subnet_range
      allowscheduling = var.allow_scheduling_on_controlplane
    })
  ]
  depends_on = [hcloud_load_balancer.controlplane_load_balancer]
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [hcloud_load_balancer.controlplane_load_balancer.ipv4]
}

resource "hcloud_server" "controlplane_server" {
  name        = "${var.cluster_name}-controlplane-${count.index}"
  count       = var.controlplane_count
  image       = imager_image.talos_x86.image_id
  server_type = var.controlplane_type
  location    = var.location
  labels      = { type = "talos-controlplane" }
  user_data   = data.talos_machine_configuration.controlplane.machine_configuration
  network {
    network_id = hcloud_network.network.id
    alias_ips  = []
  }
  # public_net {
  #   ipv4_enabled = false
  # }
  depends_on = [
    hcloud_network_subnet.subnet,
    hcloud_load_balancer.controlplane_load_balancer,
    talos_machine_secrets.this,
  ]
}

resource "talos_machine_bootstrap" "bootstrap" {
  count                = var.controlplane_count
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = hcloud_server.controlplane_server[count.index].ipv4_address
  node                 = hcloud_server.controlplane_server[count.index].ipv4_address
}

data "talos_machine_configuration" "worker" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${hcloud_load_balancer.controlplane_load_balancer.ipv4}:6443"
  machine_type       = "worker"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version_contract
  kubernetes_version = var.kubernetes_version
  config_patches = [
    templatefile("${path.module}/patches/worker.yaml.tmpl", {
      subnet = var.private_network_subnet_range
    })
  ]
  depends_on = [hcloud_load_balancer.controlplane_load_balancer]
}

resource "hcloud_server" "worker_server" {
  for_each    = var.workers
  name        = each.value.name
  image       = imager_image.talos_x86.image_id
  server_type = each.value.server_type
  location    = each.value.location
  labels      = { type = "talos-worker" }
  user_data   = data.talos_machine_configuration.worker.machine_configuration
  network {
    network_id = hcloud_network.network.id
    alias_ips  = []
  }
  depends_on = [
    hcloud_network_subnet.subnet,
    hcloud_load_balancer.controlplane_load_balancer,
  ]
}

resource "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = hcloud_load_balancer.controlplane_load_balancer.ipv4
  depends_on = [
    hcloud_load_balancer.controlplane_load_balancer,
    hcloud_server.controlplane_server,
  ]
}

resource "local_file" "talosconfig" {
  filename = "../config/talosconfig"
  content  = data.talos_client_configuration.this.talos_config
}

resource "local_file" "kubeconfig" {
  filename = "../config/kubeconfig"
  content  = talos_cluster_kubeconfig.this.kubeconfig_raw
}

resource "kubernetes_namespace_v1" "flux-system" {
  metadata {
    name = "flux-system"
  }
  depends_on = [local_file.kubeconfig]
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
  path               = "clusters/production"
}
