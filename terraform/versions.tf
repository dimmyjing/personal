terraform {
  required_version = "~> 1.11"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.60"
    }

    talos = {
      source  = "siderolabs/talos"
      version = "0.11.0-beta.1"
    }

    imager = {
      source  = "hcloud-talos/imager"
      version = "~> 0.1"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.7"
    }

    flux = {
      source  = "fluxcd/flux"
      version = "~> 1.8"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.19"
    }
  }

  encryption {
    key_provider "pbkdf2" "encryption_key" {
      passphrase = var.state_passphrase
    }

    method "aes_gcm" "default" {
      keys = key_provider.pbkdf2.encryption_key
    }

    state {
      method = method.aes_gcm.default
    }

    plan {
      method = method.aes_gcm.default
    }
  }
}
