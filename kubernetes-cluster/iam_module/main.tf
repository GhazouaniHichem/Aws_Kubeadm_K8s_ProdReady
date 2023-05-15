# -- iam/main.tf -- 

#Policy for Lambda to assume IAM role
resource "aws_iam_role" "lambda_role" {
  name = "assume-lambda-role"
  #References a file from the iam directory that has the Lambda's assume role IAM policy
  assume_role_policy = file("${path.module}/iam_role.txt")
}

#Policy for the IAM role to use
resource "aws_iam_policy" "iam_policy_for_lambda_role" {
  name        = "aws-policy-for-assume_role"
  description = "AWS IAM Policy for managing assume-lambda-role"
  #References a file from the iam directory that has the IAM policy for the role assumed
  policy = file("${path.module}/iam_policy.txt")
}

#Attach the IAM policy to the role
resource "aws_iam_role_policy_attachment" "role_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.iam_policy_for_lambda_role.arn
}










