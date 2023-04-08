terraform {
   backend "s3" {
    bucket = "terraform.tfstate.mydomaine.com"
    key    = "KubernetesCluster.tfstate"
    region = "eu-west-3"
  }
}
module "kubernetes" {
  source = "./kubernetes"
  cluster_name = var.cluster_name
  master_instance_type = var.master_instance_type
  nodes_max_size = var.nodes_max_size
  nodes_min_size = var.nodes_min_size
  nodes_desired_size = var.nodes_desired_size
  worker_instance_type = var.worker_instance_type
  vpc_name = "kubernetes_vpc"
}
