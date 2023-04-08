#-- iam/outputs.tf --

output "lambda_role_arn" {
  value = aws_iam_role.lambda_role.arn
}

output "role_policy_attachment" {
  value = aws_iam_role_policy_attachment.role_policy_attachment
}