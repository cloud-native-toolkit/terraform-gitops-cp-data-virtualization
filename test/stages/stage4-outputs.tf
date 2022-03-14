
resource null_resource write_outputs {
  provisioner "local-exec" {
    command = "echo \"$${OUTPUT}\" > gitops-output.json"

    environment = {
      OUTPUT = jsonencode({
        name        = module.cpd-dv-provision.name
        cpd_namespace = module.cpd-dv-provision.cpd_namespace
        branch      = module.cpd-dv-provision.branch
        namespace   = module.cpd-dv-provision.namespace
        server_name = module.cpd-dv-provision.server_name
        layer       = module.cpd-dv-provision.layer
        layer_dir   = module.cpd-dv-provision.layer == "infrastructure" ? "1-infrastructure" : (module.cpd-dv-provision.layer == "services" ? "2-services" : "3-applications")
        type        = module.cpd-dv-provision.type
      })
    }
  }
}
