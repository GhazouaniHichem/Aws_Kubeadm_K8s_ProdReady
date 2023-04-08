#! /bin/bash

# STEP 1 - Prepare all nodes with Kubernetes Packages

hostnamectl set-hostname $(curl -s http://169.254.169.254/latest/meta-data/local-hostname)

echo "Setting up docker"
sudo su
apt update -y
apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
apt update -y
apt-cache policy docker-ce
apt install -y docker-ce

mkdir /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=cgroupfs"],
  "log-driver": "json-file",
  "log-opts": {
      "max-size": "100m"
      },
  "storage-driver": "overlay2"
}
EOF
systemctl enable --now docker
usermod -aG docker ubuntu
systemctl daemon-reload
systemctl restart docker

echo "Disabling SWAP"
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sysctl net.bridge.bridge-nf-call-iptables=1

echo "Disabling Firewall"
sudo ufw disable

echo "Installing Kubelet,Kubeadm,Kubectl"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update -y
apt-get install -y kubelet kubeadm
apt-mark hold kubelet kubeadm

sudo tee /etc/default/kubelet <<EOF
KUBELET_EXTRA_ARGS="--cgroup-driver=cgroupfs"
EOF

systemctl daemon-reload
systemctl restart kubelet


sudo apt remove containerd
sudo apt update
sudo apt install containerd.io
sudo rm /etc/containerd/config.toml
sudo systemctl restart containerd

sudo apt install awscli -y
sleep 10
sudo aws lambda invoke --function-name join_cmd_function --region eu-west-3 --payload '{}' response.json