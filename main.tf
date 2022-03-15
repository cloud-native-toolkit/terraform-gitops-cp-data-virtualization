locals {
  name          = "cpd-dv-provision"
  bin_dir       = module.setup_clis.bin_dir
  prerequisites_name = "cpd-dv-provision-prereqs"
  yaml_dir      = "${path.cwd}/.tmp/${local.name}/chart/${local.name}"
  prerequisites_yaml_dir = "${path.cwd}/.tmp/${local.name}/chart/${local.prerequisites_name}"
  service_url   = "http://${local.name}.${var.namespace}"
  values_content = {
    SERVICE_INSTANCE_NAMESPACE = var.cpd_namespace
    ZEN_OPERATORS_NAMESPACE = var.operator_namespace
    MEMORY_REQUEST_SIZE = "24Gi"
    CPU_REQUEST_SIZE= "6"
    PERSISTENCE_STORAGE_CLASS = "portworx-db2-rwx-sc"
    PERSISTENCE_STORAGE_SIZE = "50Gi"
    CACHING_STORAGE_CLASS = "portworx-db2-rwx-sc"
    CACHING_STORAGE_SIZE = "50Gi"
    WORKER_STORAGE_CLASS = "portworx-db2-rwx-sc"
    WORKER_STORAGE_SIZE = "50Gi"
    NUMBER_OF_WORKERS = "1"
  }
  layer = "services"
  type  = "base"
  application_branch = "main"
  namespace = var.namespace
  layer_config = var.gitops_config[local.layer]
  cpd_namespace = var.cpd_namespace
}

module setup_clis {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"
}

module setup_service_account {
  source = "github.com/cloud-native-toolkit/terraform-gitops-service-account.git"

  gitops_config = var.gitops_config
  git_credentials = var.git_credentials
  namespace = var.cpd_namespace
  name = var.service_account_name
  server_name = var.server_name  
}

module setup_rbac {
  source = "github.com/cloud-native-toolkit/terraform-gitops-rbac.git?ref=v1.7.1"

  gitops_config             = var.gitops_config
  git_credentials           = var.git_credentials
  service_account_namespace = var.cpd_namespace
  service_account_name      = var.service_account_name
  namespace                 = var.cpd_namespace
  rules                     = [
    {
      apiGroups = ["cpd.ibm.com"]
      resources = ["ibmcpds"]
      verbs = ["get", "watch", "list"]
    },
    {
      apiGroups = ["rbac.authorization.k8s.io"]
      resources = ["roles"]
      verbs = ["get", "watch", "list", "create", "patch"]
    },
    {
      apiGroups = ["rbac.authorization.k8s.io"]
      resources = ["rolebindings"]
      verbs = ["get", "watch", "list", "create", "patch"]
    },
    {
      apiGroups = ["db2u.databases.ibm.com"]
      resources = ["bigsqls"]
      verbs = ["create", "delete", "get", "list", "patch", "update"]
    },
    {
      apiGroups = ["db2u.databases.ibm.com"]
      resources = ["db2uclusters"]
      verbs = ["create", "delete", "get", "list", "patch", "update"]
    },
    {
      apiGroups = ["db2u.databases.ibm.com"]
      resources = ["dvs"]
      verbs = ["create", "delete", "get", "list", "patch", "update"]
    },
    {
      apiGroups = ["db2u.databases.ibm.com"]
      resources = ["dvservices"]
      verbs = ["create", "delete", "get", "list", "patch", "update"]
    },
    {
      apiGroups = ["apiextensions.k8s.io"]
      resources = ["customresourcedefinitions"]
      verbs = ["create", "delete", "get", "list", "patch", "update"]
    },
    {
      apiGroups = ["apps"]
      resources = ["statefulsets"]
      verbs = ["create", "delete", "get", "list", "patch", "update"]
    },
    {
      apiGroups = [""]
      resources = ["apps"]
      verbs = ["create", "delete", "get", "list", "patch", "update"]
    }
  ]
  server_name               = var.server_name
  cluster_scope             = true
}

resource null_resource create_prerequisites_yaml {
  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${local.prerequisites_name}' '${local.prerequisites_yaml_dir}'"

    environment = {
      VALUES_CONTENT = yamlencode(local.values_content)
    }
  }
}

resource null_resource setup_prerequisites_gitops {
  depends_on = [null_resource.create_prerequisites_yaml]

  triggers = {
    name = local.prerequisites_name
    namespace = var.cpd_namespace
    yaml_dir = local.prerequisites_yaml_dir
    server_name = var.server_name
    layer = local.layer
    type = local.type
    git_credentials = yamlencode(var.git_credentials)
    gitops_config   = yamlencode(var.gitops_config)
    bin_dir = local.bin_dir
  }

  provisioner "local-exec" {
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type '${self.triggers.type}'"

    environment = {
      GIT_CREDENTIALS = nonsensitive(self.triggers.git_credentials)
      GITOPS_CONFIG   = self.triggers.gitops_config
    }
  }

  provisioner "local-exec" {
    when = destroy
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --delete --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type '${self.triggers.type}'"

    environment = {
      GIT_CREDENTIALS = nonsensitive(self.triggers.git_credentials)
      GITOPS_CONFIG   = self.triggers.gitops_config
    }
  }
}

resource null_resource create_yaml {
  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${local.name}' '${local.yaml_dir}'"

    environment = {
      VALUES_CONTENT = yamlencode(local.values_content)
    }
  }
}

resource null_resource setup_gitops {
  depends_on = [null_resource.create_yaml]

  triggers = {
    name = local.name
    namespace = var.cpd_namespace
    yaml_dir = local.yaml_dir
    server_name = var.server_name
    layer = local.layer
    type = local.type
    git_credentials = yamlencode(var.git_credentials)
    gitops_config   = yamlencode(var.gitops_config)
    bin_dir = local.bin_dir
  }

  provisioner "local-exec" {
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type '${self.triggers.type}'"

    environment = {
      GIT_CREDENTIALS = nonsensitive(self.triggers.git_credentials)
      GITOPS_CONFIG   = self.triggers.gitops_config
    }
  }

  provisioner "local-exec" {
    when = destroy
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --delete --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type '${self.triggers.type}'"

    environment = {
      GIT_CREDENTIALS = nonsensitive(self.triggers.git_credentials)
      GITOPS_CONFIG   = self.triggers.gitops_config
    }
  }
}
