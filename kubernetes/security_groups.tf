resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



resource "aws_security_group" "bastion_node" {
  name        = "bastion_node"
  description = "Allow required traffic to the bastion node"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from outside"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg_bastion"
  }
}


resource "aws_security_group" "k8_nodes" {
  name        = "k8_nodes"
  description = "sec group for k8 nodes"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_security_group" "k8s_worker_nodes" {
  name        = "k8s_workers_${var.cluster_name}"
  description = "Worker nodes security group"
  vpc_id      = aws_vpc.main.id
  ingress {
    #Kubelet API
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    #NodePort Services†
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }
  tags = {
    Name                                        = "${var.cluster_name}_nodes"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

resource "aws_security_group" "k8s_master_nodes" {
  name        = "k8s_masters_${var.cluster_name}"
  description = "Master nodes security group"
  vpc_id      = aws_vpc.main.id
    ingress {
    #Kubernetes API server
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"] # for elb internal use only

  }

  
  ingress {
    #etcd server client API
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  ingress {
    #Kubelet API
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  ingress {
    #kube-scheduler
    from_port   = 10259
    to_port     = 10259
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  ingress {
    #kube-controller-manager
    from_port   = 10257
    to_port     = 10257
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }
  tags = {
    Name                                        = "${var.cluster_name}_nodes"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

resource "aws_security_group_rule" "traffic_from_lb" {
  type              = "ingress"
  description       = "Allow API traffic from the load balancer"
  security_group_id = aws_security_group.k8s_master_nodes.id
  from_port         = 6443
  to_port           = 6443
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "traffic_from_workers_to_masters" {
  type                     = "ingress"
  description              = "Traffic from the worker nodes to the master nodes is allowed"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.k8s_master_nodes.id
  source_security_group_id = aws_security_group.k8s_worker_nodes.id
}

resource "aws_security_group_rule" "traffic_from_bastion_to_masters" {
  type                     = "ingress"
  description              = "Traffic from the bastion node to the master node is allowed"
  from_port                = 22
  to_port                  = 22
  protocol                 = "TCP"
  security_group_id        = aws_security_group.k8s_master_nodes.id
  source_security_group_id = aws_security_group.bastion_node.id
}
