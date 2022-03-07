
resource null_resource write_outputs {
  provisioner "local-exec" {
    command = "echo \"$${OUTPUT}\" > gitops-output.json"

    environment = {
      OUTPUT = jsonencode({
        name        = module.gitops_cp4d_dv_instance.name
        branch      = module.gitops_cp4d_dv_instance.branch
        namespace   = module.gitops_cp4d_dv_instance.namespace
        server_name = module.gitops_cp4d_dv_instance.server_name
        layer       = module.gitops_cp4d_dv_instance.layer
        layer_dir   = module.gitops_cp4d_dv_instance.layer == "infrastructure" ? "1-infrastructure" : (module.gitops_cp4d_dv_instance.layer == "services" ? "2-services" : "3-applications")
        type        = module.gitops_cp4d_dv_instance.type
      })
    }
  }
}
