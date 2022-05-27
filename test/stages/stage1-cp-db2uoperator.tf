module "db2u" {  
  source = "./module"

  depends_on = [
        module.gitops_namespace
    ]

  gitops_config = module.gitops.gitops_config
  git_credentials = module.gitops.git_credentials
  server_name = module.gitops.server_name  
  operator_namespace = "cpd-operators"
  kubeseal_cert = module.gitops.sealed_secrets_cert
}