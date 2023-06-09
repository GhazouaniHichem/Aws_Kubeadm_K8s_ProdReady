#terraform {
#   backend "s3" {
#    bucket = "terraform.tfstate.mydomaine.com"
#    key    = "KubernetesCluster.tfstate"
#    region = "eu-west-3"
#  }
#}


module "kubernetes" {
  
  source = "./kubernetes-cluster"
  region = var.AWS_REGION
  cluster_name = var.cluster_name
  vpc_name = var.vpc_name
  vpc_cidr = var.vpc_cidr
  ami_id = var.ami_id
  ssh_user = var.ssh_user
  master_instance_type = var.master_instance_type
  master_node_count = var.master_node_count
  nodes_max_size = var.nodes_max_size
  nodes_min_size = var.nodes_min_size
  nodes_desired_size = var.nodes_desired_size
  worker_instance_type = var.worker_instance_type
  
}

resource "time_sleep" "wait_3_minutes" {

  depends_on = [module.kubernetes]
  create_duration = "180s"

}


module "helm_charts" { 

  source = "./helm-charts"
  kube_config = var.kube_config
  depends_on = [ module.kubernetes, time_sleep.wait_3_minutes ]
  
}

