# module "cp4d-dv-service" {
#   source = "github.com/cloud-native-toolkit/terraform-gitops-cp-data-virtualization-service"

#   depends_on = [
#     module.cp4d_instance
#   ]

#   gitops_config = module.gitops.gitops_config
#   git_credentials = module.gitops.git_credentials
#   server_name = module.gitops.server_name
#   namespace = module.gitops_namespace.name
#   operator_namespace = module.gitops_cpd_operator_namespace.name
#   cpd_namespace = "gitops-cp4d-instance"
#   kubeseal_cert = module.gitops.sealed_secrets_cert
# }