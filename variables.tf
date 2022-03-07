
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

variable "cluster_ingress_hostname" {
  type        = string
  description = "Ingress hostname of the IKS cluster."
  default     = ""
}

variable "operator_namespace" {
  type        = string
  description = "operator namespace"
  default     = "cpd-operators"
}

variable "cpd_namespace" {
  type        = string
  description = "cpd namespace"
  default     = "gitops-cp4d-instance"
}

variable "memory_request_size" {
  type        = string
  description = "Memory size"
  default     = "16Gi"
}

variable "cpu_request_size" {
  type        = string
  description = "CPU size"
  default     = "4"
}

variable "persistence_storage_class" {
  type        = string
  description = "Persistence Strage Class"
  default     = "portworx-db2-rwx-sc"
}

variable "persistence_storage_size" {
  type        = string
  description = "Persistence Strage Size"
  default     = "50Gi"
}

variable "caching_storage_class" {
  type        = string
  description = "Caching Strage Class"
  default     = "portworx-db2-rwx-sc"
}

variable "caching_storage_size" {
  type        = string
  description = "Caching Strage Size"
  default     = "50Gi"
}

variable "worker_storage_class" {
  type        = string
  description = "Worker Strage Class"
  default     = "portworx-db2-rwx-sc"
}

variable "worker_storage_size" {
  type        = string
  description = "Worker Strage Size"
  default     = "50Gi"
}

variable "number_of_workers" {
  type        = string
  description = "Number of Workers"
  default     = "1"
}