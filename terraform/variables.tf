variable "state_passphrase" {
  sensitive = true
  type      = string
}

variable "hcloud_token" {
  sensitive = true
  type      = string
}

variable "imager_server_type" {
  type    = string
  default = "cpx11"
}

variable "cluster_name" {
  description = "A name to provide for the Talos cluster"
  type        = string
  default     = "talos-cluster"
}

variable "talos_version_contract" {
  description = "Talos API version to use for the cluster, if not set the the version shipped with the talos sdk version will be used"
  type        = string
  default     = "v1.12"
}

variable "talos_version" {
  description = "Talos version to use for the cluster"
  type        = string
  default     = "v1.12.4"
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the cluster, if not set the k8s version shipped with the talos sdk version will be used"
  type        = string
  default     = null
}

variable "controlplane_count" {
  description = "Number of control plane nodes to create"
  type        = number
  default     = 1
}

variable "controlplane_type" {
  type    = string
  default = "cpx11"
}

variable "allow_scheduling_on_controlplane" {
  description = "Allow scheduling on control plane nodes"
  type        = bool
  default     = false
}

variable "private_network_name" {
  type    = string
  default = "talos-network"
}

variable "private_network_ip_range" {
  type    = string
  default = "10.0.0.0/16"
}

variable "private_network_subnet_range" {
  type    = string
  default = "10.0.0.0/24"
}

variable "network_zone" {
  type    = string
  default = "us-east"
}

variable "load_balancer_type" {
  type    = string
  default = "lb11"
}

variable "location" {
  type    = string
  default = "ash"
}

variable "workers" {
  description = "Worker definition"
  type = map(object({
    name        = string
    server_type = string
    location    = string
  }))
}

variable "flux_git_repo_url" {
  description = "Git repository URL for FluxCD"
  type        = string
  default     = "https://github.com/dimmyjing/personal"
}

variable "flux_author_email" {
  description = "Author email for FluxCD Git commits"
  type        = string
  default     = "git@jimmyding.com"
}

variable "github_token" {
  description = "GitHub Token for accessing private repositories"
  type        = string
  sensitive   = true
}

# variable "backblaze_master_key" {
#   sensitive = true
# }
