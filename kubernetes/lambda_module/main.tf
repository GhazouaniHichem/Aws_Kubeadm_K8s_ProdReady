# -- lambda/main.tf --

#Create Lambda function that implements Python code
#This function will stop the instances labeled Dev
resource "aws_lambda_function" "lambda_function" {
  #Uses the Python file that is zipped in main.tf
  filename      = var.filename
  function_name = "join_cmd_function"
  #Attach IAM role to Lambda
  role          = var.lambda_role_arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"
  timeout       = 60
  #Wait until IAM Policy is attached to IAM role before creating
  depends_on    = [var.role_policy_attachment]
}

