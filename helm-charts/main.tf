module "prometheus" {
  source = "./prometheus-helm"
}


module "istio" {
  source = "./istio-helm"
}

module "argocd" {
  source = "./argocd-helm"
}

module "argo-rollouts" {
  source = "./argo-rollouts-helm"
}
