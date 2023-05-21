#Defines variable I wll use to name the Lambda I'm creating
locals {
  lambda_name = "join_k8s_cluster"
}

#Module containing IAM permissions used by Lambda
module "iam_module" {
  source = "./iam_module"
}

#Defines a data resource of type "archive_file" named "zip_the_python_code". 
data "archive_file" "zip_the_python_code" {
  type = "zip"
  source_dir = "${path.module}/lambda_python_code/"
  output_path = "${path.module}/lambda_python_code/${local.lambda_name}.zip"
}


#Module creating the actual Lambda
module "lambda_module" {
  source      = "./lambda_module"
  lambda_name = local.lambda_name
  filename = "${path.module}/lambda_python_code/${local.lambda_name}.zip"
  lambda_role_arn        = module.iam_module.lambda_role_arn
  role_policy_attachment = module.iam_module.role_policy_attachment
#  topic_arn = aws_sns_topic.worker_asg_topic.arn
}





### Notifications:

resource "aws_sns_topic" "worker_asg_topic" {
  name = "workers_topic"
}


resource "aws_autoscaling_notification" "worker_asg_notifications" {
  group_names = [
    aws_autoscaling_group.nodes-k8s.name,
  ]
  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
  ]
  topic_arn = aws_sns_topic.worker_asg_topic.arn
}







