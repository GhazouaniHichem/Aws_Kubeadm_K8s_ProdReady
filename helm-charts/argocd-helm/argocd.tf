resource "helm_release" "argocd" {

  name       = "argo-cd"

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "4.9.8"
  namespace  = "argocd"
  create_namespace = true 

  ## params
  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }

  set { # Define the application controller --app-resync - refresh interval for apps, default is 180 seconds
    name  = "controller.args.appResyncPeriod"
    value = "60"
  }

  set { # Define the application controller --repo-server-timeout-seconds - repo refresh timeout, default is 60 seconds
    name  = "controller.args.repoServerTimeoutSeconds"
    value = "30"
  }


}