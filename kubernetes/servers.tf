#Bastion
resource "aws_instance" "bastion" {
  ami                         = var.ami_id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.utility.id
  associate_public_ip_address = "true"
  security_groups             = [aws_security_group.allow_ssh.id]
  key_name                    = aws_key_pair.k8_ssh.key_name
  user_data = <<-EOF
                #!bin/bash
                echo "PubkeyAcceptedKeyTypes=+ssh-rsa" >> /etc/ssh/sshd_config.d/10-insecure-rsa-keysig.conf
                systemctl reload sshd
                echo "${tls_private_key.ssh.private_key_pem}" >> /home/ubuntu/.ssh/id_rsa
                chown ubuntu /home/ubuntu/.ssh/id_rsa
                chgrp ubuntu /home/ubuntu/.ssh/id_rsa
                chmod 600   /home/ubuntu/.ssh/id_rsa
                echo "starting ansible install"
                apt-add-repository ppa:ansible/ansible -y
                apt update
                apt install ansible -y
                EOF

  tags = {
    Name = "bastion.${var.cluster_name}"
  }
}

#Masters

resource "aws_instance" "masters" {
  count           = var.master_node_count
  ami             = var.ami_id
  instance_type   = var.master_instance_type
  subnet_id       = element(aws_subnet.public.*.id, count.index)
  key_name        = aws_key_pair.k8_ssh.key_name
  security_groups = [aws_security_group.k8_nodes.id, aws_security_group.k8s_master_nodes.id]
  iam_instance_profile = aws_iam_instance_profile.terraform_k8s_master_role-Instance-Profile.name
  user_data            = <<EOT
#!/bin/bash
hostnamectl set-hostname $(curl -s http://169.254.169.254/latest/meta-data/local-hostname)
EOT

  tags = {
    Name = "masters.${var.cluster_name}"
    "KubernetesCluster" = var.cluster_name
    "k8s.io/role/master" = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"

  }
}

