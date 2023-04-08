resource "aws_lb" "k8_masters_lb" {
  name               = "api-${var.cluster_name}"
 # Check type of connection private or public needed !!!!!!!!!!!!
  internal = true 
  load_balancer_type = "network"
  subnets            = [for subnet in aws_subnet.private : subnet.id]
  tags = {
    KubernetesCluster                           = var.cluster_name
    Name                                        = "api.${var.cluster_name}"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }

}

# target_type instance not working well when we bound this LB as a control-plane-endpoint. hence had to use IP target_type


resource "aws_lb_target_group" "k8_masters_api" {
  name     = "control-plane"
  port        = 6443
  protocol    = "TCP"
  vpc_id   = aws_vpc.main.id
  target_type = "ip"

  health_check {
    port                = 6443
    protocol            = "TCP"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

}

resource "aws_lb_listener" "k8_masters_lb_listener" {
  load_balancer_arn = aws_lb.k8_masters_lb.arn
  port              = 6443
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.k8_masters_api.id
    type             = "forward"
  }
}

resource "aws_lb_target_group_attachment" "k8_masters_attachment" {
  count            = length(aws_instance.masters.*.id)
  target_group_arn = aws_lb_target_group.k8_masters_api.arn
  target_id        = aws_instance.masters.*.private_ip[count.index]
}
