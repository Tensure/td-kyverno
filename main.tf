provider "kubernetes" {
  config_path = pathexpand("~/.kube/config")
}

provider "helm" {
  kubernetes {
    config_path = pathexpand("~/.kube/config")
  }
}

locals {
  prodClusterName = "kyverno-demo"
  environment = "dev"

  addons = {
    enable_argocd  = true
    enable_kyverno = true
  }
  
  annotations = merge({
        cluster_name = local.prodClusterName
        environment  = local.environment
    }, local.metadata)

  argocd_labels = merge({
    cluster_name                     = local.prodClusterName
    environment                      = local.environment
    enable_argocd                    = true
    "argocd.argoproj.io/secret-type" = "cluster"
    },
    local.addons,
  )

  metadata = merge(
    {
      cluster_name = local.prodClusterName
      environment  = local.environment
      managed-by   = "argocd.argoproj.io"
      argocd_namespace = "argocd"
      addons_name          = "addons-repo"
      addons_repo_name     = "addons-repo"
      addons_repo_url      = "https://github.com/JoeKer1/gitops-demos.git"
      addons_repo_basepath = ""
      addons_repo_path     = "bootstrap/control-plane/addons"
      addons_repo_revision = "main"
    }
  )


  argocd_apps = {
    addons = file("${path.module}/bootstrap/addons.yaml")
  }

  config = <<-EOT
    {
      "tlsClientConfig": {
        "insecure": false
      }
    }
  EOT
  argocd = {
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name        = local.prodClusterName
      namespace   = "argocd"
      annotations = local.annotations
      labels      = local.argocd_labels
    }
    stringData = {
      name   = local.prodClusterName
      server = "https://kubernetes.default.svc"
      config = local.config
    }
  }
}


# -------------- #
# Install ArgoCD #
# -------------- #

resource "helm_release" "argocd" {
  # https://github.com/argoproj/argo-helm/blob/main/charts/argo-cd/Chart.yaml
  # (there is no offical helm chart for argocd)
  name             = "argo-cd"
  description      = "A Helm chart to install the ArgoCD"
  namespace        = "argocd"
  create_namespace = true
  chart            = "argo-cd"
  version          = "7.8.2"
  repository       = "https://argoproj.github.io/argo-helm"

  skip_crds        = false

  # this sets our super secret password for our local kind cluster
  set {
    name = "configs.secret.argocdServerAdminPassword"
    value = "$2a$10$h9Eb./X68WocvlfDJBRh.uC3bo0AozLR4aO/0emB2RKFOWxuIsPyS"
  }

}

resource "kubernetes_secret_v1" "cluster" {

  metadata {
    name        = local.prodClusterName
    namespace   = local.metadata.argocd_namespace
    annotations = local.annotations
    labels      = local.argocd_labels
  }
  data = local.argocd.stringData

  depends_on = [helm_release.argocd]
}


resource "helm_release" "bootstrap" {
  for_each = local.argocd_apps
  name      = each.key
  namespace = "argocd"
  chart     = "${path.module}/charts/resources"
  version   = "1.0.0"

  values = [
    <<-EOT
    resources:
      - ${indent(4, each.value)}
    EOT
  ]

  depends_on = [resource.kubernetes_secret_v1.cluster]
}