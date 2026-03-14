variable "state_passphrase" {
  sensitive = true
  type      = string
}

variable "hcloud_token" {
  sensitive = true
  type      = string
}

variable "cloudflare_api_token" {
  sensitive = true
  type      = string
}

variable "github_token" {
  description = "GitHub Token for accessing private repositories"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  type    = string
  default = "4c851bd554509d95338679aa85bd22e1"
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

variable "talos_version" {
  description = "Talos version to use for the cluster"
  type        = string
  default     = "v1.12.4"
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the cluster, if not set the k8s version shipped with the talos sdk version will be used"
  type        = string
  default     = "1.35.2"
}

variable "cilium_version" {
  description = "Cilium version to deploy"
  type        = string
  default     = "1.19.1"
}

variable "controlplane_count" {
  description = "Number of control plane nodes to create"
  type        = number
  default     = 3
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

variable "cluster_api_host" {
  description = "API host for the Kubernetes cluster"
  type        = string
  default     = "kube.jimmyding.com"
}

variable "location" {
  type    = string
  default = "ash"
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

# variable "backblaze_master_key" {
#   sensitive = true
# }
