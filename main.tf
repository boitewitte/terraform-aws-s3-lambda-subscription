module "label" {
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.2.1"
  namespace  = "${var.namespace}"
  stage      = "${var.environment}"
  name       = "${var.name}"
  tags       = "${var.tags}"
}

data "aws_iam_policy_document" "logs" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]

    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

resource "aws_iam_role_policy" "logs_policy" {
  name = "${module.label.id}-logs"
  role = "${aws_iam_role.role.id}"

  policy = "${data.aws_iam_policy_document.logs.json}"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    sid = ""

    actions = [
      "sts:AssumeRole"
    ]

    principals = {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# NOT WORKING
# gives error: lambda_function.0.events required field not set
# resource "aws_s3_bucket_notification" "this" {
#   bucket = "${var.bucket_id}"

#   lambda_function = ["${merge(map("lambda_function_arn", aws_lambda_function.this.arn), var.bucket_notification)}"]
# }

resource "aws_lambda_permission" "this" {
  statement_id        = "AllowExecutionFromS3Bucket"
  action              = "lambda:InvokeFunction"

  function_name       = "${aws_lambda_function.this.function_name}"
  principal           = "s3.amazonaws.com"

  source_arn          = "${var.bucket_arn}"
}

resource "aws_iam_role" "role" {
  name = "${module.label.id}"

  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
}

resource "aws_iam_role_policy_attachment" "custom" {
  count                 = "${var.execution_policies_count}"

  role                  = "${aws_iam_role.role.name}"

  policy_arn            = "${element(var.execution_policies, count.index)}"
}

resource "aws_lambda_function" "this" {
  filename            = "${var.filename}"

  function_name       = "${module.label.id}"
  role                = "${aws_iam_role.role.arn}"

  # handler             = "invoice-saved.s3"
  handler             = "${var.handler}"
  # nodejs8.10
  # runtime             = "nodejs6.10"
  runtime             = "${var.runtime}"
  source_code_hash    = "${base64sha256(file(var.filename))}"
  # memory_size         = "128"
  memory_size         = "${var.memory_size}"
  # timeout             = "60"
  timeout             = "${var.timeout}"

  tags                = "${module.label.tags}"

  environment         = {
    variables           = "${merge(module.label.tags, var.environment_variables)}"
  }
}

