provider "hcloud" {
  token = var.hcloud_token
}

provider "imager" {
  token = var.hcloud_token
}

provider "talos" {}

provider "local" {}

provider "kubernetes" {
  config_path = "../config/kubeconfig"
}

provider "kubectl" {
  config_path = "../config/kubeconfig"
}

provider "flux" {
  kubernetes = {
    config_path = "../config/kubeconfig"
  }
  git = {
    url          = var.flux_git_repo_url
    author_email = var.flux_author_email
    http = {
      username = "git"
      password = var.github_token
    }
  }
}
