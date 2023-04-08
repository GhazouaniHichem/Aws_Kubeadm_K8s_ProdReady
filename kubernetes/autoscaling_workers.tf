#Worker

resource "aws_launch_configuration" "worker-nodes-k8s-local" {
  name_prefix          = "nodes.${var.cluster_name}."
  image_id             = var.ami_id
  instance_type        = var.worker_instance_type
  key_name             = aws_key_pair.k8_ssh.key_name
  iam_instance_profile = aws_iam_instance_profile.terraform_k8s_worker_role-Instance-Profile.name
  security_groups      = [aws_security_group.k8_nodes.id, aws_security_group.k8s_worker_nodes.id]
  user_data            = file("${path.module}/kubeadm-scripts/worker_script.sh")

  lifecycle {
    create_before_destroy = true
  }
  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
  }

    depends_on = [
      null_resource.provisioner,
      null_resource.copy_ansible_playbooks,
      aws_instance.masters,
      aws_vpc.main,
      aws_instance.bastion,
      time_sleep.wait_for_bastion_init,
      null_resource.run_ansible
      ]
}


resource "aws_autoscaling_group" "nodes-k8s" {
  name                 = "${var.cluster_name}_workers"
  launch_configuration = aws_launch_configuration.worker-nodes-k8s-local.id
  max_size             = var.nodes_max_size
  min_size             = var.nodes_min_size
  desired_capacity     = var.nodes_desired_size
  vpc_zone_identifier  = aws_subnet.private.*.id


  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity = "1Minute"

  tag {
    key                 = "KubernetesCluster"
    value               = var.cluster_name
    propagate_at_launch = true
  }
  tag {
    key                 = "Name"
    value               = "nodes.${var.cluster_name}"
    propagate_at_launch = true
  }
  tag {
    key                 = "k8s.io/role/node"
    value               = "1"
    propagate_at_launch = true
  }
  tag {
    key                 = "kubernetes.io/cluster/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }
}



# scale up policy
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.cluster_name}-asg-scale-up"
  autoscaling_group_name = aws_autoscaling_group.nodes-k8s.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1" #increasing instance by 1 
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

# scale up alarm
# alarm will trigger the ASG policy (scale/down) based on the metric (CPUUtilization), comparison_operator, threshold
resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "${var.cluster_name}-asg-scale-up-alarm"
  alarm_description   = "asg-scale-up-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "40" # New instance will be created once CPU utilization is higher than 30 %
  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.nodes-k8s.name
  }
  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.scale_up.arn]
}

# scale down policy
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.cluster_name}-asg-scale-down"
  autoscaling_group_name = aws_autoscaling_group.nodes-k8s.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1" # decreasing instance by 1 
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

# scale down alarm
resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name          = "${var.cluster_name}-asg-scale-down-alarm"
  alarm_description   = "asg-scale-down-cpu-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "5" # Instance will scale down when CPU utilization is lower than 5 %
  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.nodes-k8s.name
  }
  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.scale_down.arn]
}

