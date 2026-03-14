provider "imager" {
  token = var.hcloud_token
}

provider "local" {}

provider "kubernetes" {
  host                   = module.talos.kubeconfig_data.host
  client_certificate     = module.talos.kubeconfig_data.client_certificate
  client_key             = module.talos.kubeconfig_data.client_key
  cluster_ca_certificate = module.talos.kubeconfig_data.cluster_ca_certificate
}

provider "flux" {
  kubernetes = {
    host                   = module.talos.kubeconfig_data.host
    client_certificate     = module.talos.kubeconfig_data.client_certificate
    client_key             = module.talos.kubeconfig_data.client_key
    cluster_ca_certificate = module.talos.kubeconfig_data.cluster_ca_certificate
  }
  git = {
    url          = var.flux_git_repo_url
    author_email = var.flux_author_email
    http         = { username = "git", password = var.github_token }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
