output "test" {
  value = ["${merge(map("lambda_function_arn", aws_lambda_function.this.arn), var.bucket_notification)}"]
}

output "function_arn" {
  value = "${aws_lambda_function.this.arn}"
}

output "role_name" {
  value = "${aws_iam_role.role.name}"
}
