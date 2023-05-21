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

resource "null_resource" "istio_addons" {
  provisioner "local-exec" {
    command     = <<-EOT
                  kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.17/samples/addons/prometheus.yaml --kubeconfig ${var.kube_config}
                  kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.17/samples/addons/kiali.yaml --kubeconfig ${var.kube_config}
    EOT
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = base64encode(var.kube_config)
    }
  }
  depends_on = [ module.prometheus, module.argo-rollouts, module.argocd, module.istio ]
}