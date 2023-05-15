variable "AWS_REGION" {
  default = "eu-west-3"
}

# If you are using diffrent region (other than eu-west-3) please find ubuntu 22.04 ami for that region and change here.

variable "ami_id" {
  type    = string
  default = "ami-05b457b541faec0ca"
}

variable "vpc_cidr" {
  type    = string
  default = "10.2.0.0/16"
}


variable "master_node_count" {
  type    = number
  default = 1
}

variable "nodes_max_size" {
  type    = number
  default = 3
}
variable "nodes_min_size" {
  type    = number
  default = 2
}
variable "nodes_desired_size" {
  type    = number
  default = 2
}

variable "ssh_user" {
  type    = string
  default = "ubuntu"
}

variable "master_instance_type" {
  type    = string
  default = "t2.medium"
}

variable "worker_instance_type" {
  type    = string
  default = "t2.medium"
}

variable "cluster_name" {
  type    = string
  default = "basic-cluster"
}

variable "bucket_name" {
  type    = string
  default = "terraform.tfstate.devopswithghazouani.com"
}

variable "vpc_name" {
  type = string
  default = "kubernetes_vpc"
}


################################# Helm-Charts module variables #################

variable "kube_config" {
  type    = string
  default = "./config"
}