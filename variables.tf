
variable "gitops_config" {
  type        = object({
    boostrap = object({
      argocd-config = object({
        project = string
        repo = string
        url = string
        path = string
      })
    })
    infrastructure = object({
      argocd-config = object({
        project = string
        repo = string
        url = string
        path = string
      })
      payload = object({
        repo = string
        url = string
        path = string
      })
    })
    services = object({
      argocd-config = object({
        project = string
        repo = string
        url = string
        path = string
      })
      payload = object({
        repo = string
        url = string
        path = string
      })
    })
    applications = object({
      argocd-config = object({
        project = string
        repo = string
        url = string
        path = string
      })
      payload = object({
        repo = string
        url = string
        path = string
      })
    })
  })
  description = "Config information regarding the gitops repo structure"
}

variable "git_credentials" {
  type = list(object({
    repo = string
    url = string
    username = string
    token = string
  }))
  description = "The credentials for the gitops repo(s)"
  sensitive   = true
}

variable "namespace" {
  type        = string
  description = "The namespace where the application should be deployed"
}

variable "kubeseal_cert" {
  type        = string
  description = "The certificate/public key used to encrypt the sealed secrets"
  default     = ""
}

variable "server_name" {
  type        = string
  description = "The name of the server"
  default     = "default"
}

variable "cpd_namespace" {
  type        = string
  description = "CPD namespace"
  default = "cp4d"
}

variable "operator_namespace" {
  type        = string
  description = "operator namespace"
  default     = "cpd-operators"
}

variable "cpu_size" {
  type        = string
  description = "CPU Request Size"
  default     = "6"
}

variable "memory_request_size" {
  type        = string
  description = "Memory Request Size"
  default     = "16Gi"
}

variable "storage_class" {
  type        = string
  description = "Storage Class for data persistence"
  default     = "portworx-db2-rwx-sc"
}

variable "persistence_storage_size" {
  type        = string
  description = "Storage Size for data persistence"
  default     = "50Gi"
}

variable "caching_storage_size" {
  type        = string
  description = "Storage Size for Caching data"
  default     = "50Gi"
}

variable "worker_storage_size" {
  type        = string
  description = "Storage Size for workers data persistence"
  default     = "50Gi"
}

