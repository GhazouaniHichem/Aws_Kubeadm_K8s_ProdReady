# helm repo add istio https://istio-release.storage.googleapis.com/charts
# helm repo update
# helm install gateway -n istio-ingress --create-namespace istio/gateway
resource "helm_release" "gateway" {
  name = "gateway"

  repository       = "https://istio-release.storage.googleapis.com/charts"
  chart            = "gateway"
  version          = "1.17.1"
  namespace        = "istio-ingress"
  create_namespace = true


  depends_on = [
    helm_release.istio_base,
    helm_release.istiod
  ]
}