locals {
  cluster_name = "kyverno-demo"
  environment  = "dev"

  addons = {
    enable_argocd  = true
    enable_kyverno = true
  }

  metadata = {
    cluster_name         = local.cluster_name
    environment          = local.environment
    managed-by           = "argocd.argoproj.io"
    argocd_namespace     = "argocd"
    addons_repo_url      = "https://github.com/JoeKer1/gitops-demos.git"
    addons_repo_path     = "bootstrap/control-plane/addons"
    addons_repo_revision = "main"
    addons_name          = "addons-repo"
    addons_repo_basepath = ""
  }

  annotations = local.metadata

  argocd_labels = merge({
    "argocd.argoproj.io/secret-type" = "cluster"
    cluster_name                     = local.cluster_name,
    environment                      = local.environment
  }, local.addons)

  argocd_apps = {
    addons = file("${path.module}/bootstrap/addons.yaml")
  }

  config = jsonencode({
    tlsClientConfig = { insecure = false }
  })

  argocd_secret = {
    name        = local.cluster_name
    namespace   = "argocd"
    annotations = local.annotations
    labels      = local.argocd_labels
    stringData = {
      name   = local.cluster_name
      server = "https://kubernetes.default.svc"
      config = local.config
    }
  }
}

# -------------- #
# Install ArgoCD #
# -------------- #

resource "helm_release" "argocd" {
  name             = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  chart            = "argo-cd"
  version          = "9.1.4"
  repository       = "https://argoproj.github.io/argo-helm"

  values = [
    yamlencode({
      configs = {
        secret = {
          argocdServerAdminPassword = "$2a$10$h9Eb./X68WocvlfDJBRh.uC3bo0AozLR4aO/0emB2RKFOWxuIsPyS"
        }
      }
    })
  ]
}

resource "kubernetes_secret_v1" "cluster" {
  metadata {
    name        = local.argocd_secret.name
    namespace   = local.argocd_secret.namespace
    annotations = local.argocd_secret.annotations
    labels      = local.argocd_secret.labels
  }
  data = local.argocd_secret.stringData

  depends_on = [helm_release.argocd]
}

# ----------------- #
# Bootstrap Addons #
# ----------------- #

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

  depends_on = [kubernetes_secret_v1.cluster]
}
