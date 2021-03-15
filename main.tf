# Get actual region
data "aws_region" "this" {}

# Build Lambda archive
resource "null_resource" "package_lambda_code" {
  provisioner "local-exec" {
    command = "make -C ${path.module}/lambda_function build"
  }
}

data "archive_file" "this" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_function/dist/"
  output_path = "${path.module}/dist/lambda-code.zip"

  depends_on = [null_resource.package_lambda_code]
}

# Allow execution of Lambda from CloudWatch
resource "aws_cloudwatch_event_rule" "this" {
  name                = var.name
  schedule_expression = var.schedule_expression
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "this" {
  arn  = aws_lambda_function.this.arn
  rule = aws_cloudwatch_event_rule.this.name
}

resource "aws_lambda_permission" "this" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.this.arn
}

# Create a LogGroup for the Lambda
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = 7
  tags              = var.tags
}

# The lambda IAM role.
resource "aws_iam_role_policy" "this_ec2_start_instances" {
  count = var.custom_iam_role_arn == null && contains(["start", "enable"], var.action) ? 1 : 0

  name = "${var.name}StartEc2InstancesPolicy"
  role = aws_iam_role.this[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:StartInstances",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy" "this_ec2_stop_instances" {
  count = var.custom_iam_role_arn == null && contains(["stop", "disable"], var.action) ? 1 : 0

  name = "${var.name}StopEc2InstancesPolicy"
  role = aws_iam_role.this[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:StopInstances",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy" "this_autoscaling_describe_instances" {
  count = var.custom_iam_role_arn == null ? 1 : 0

  name = "${var.name}DescribeAutoScalingInstancesPolicy"
  role = aws_iam_role.this[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "autoscaling:DescribeAutoScalingInstances",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy" "this_logs_put_events" {
  count = var.custom_iam_role_arn == null ? 1 : 0

  name = "${var.name}PushLogsToCloudwatchPolicy"
  role = aws_iam_role.this[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.this.arn}:*"
      },
    ]
  })
}

# The IAM Role with which the Lambda should be executed.
resource "aws_iam_role" "this" {
  count = var.custom_iam_role_arn == null ? 1 : 0

  name = "${var.name}IamRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

# The lambda execution.
resource "aws_lambda_function" "this" {
  filename         = data.archive_file.this.output_path
  source_code_hash = data.archive_file.this.output_base64sha256
  function_name    = var.name
  role             = var.custom_iam_role_arn == null ? aws_iam_role.this[0].arn : var.custom_iam_role_arn
  handler          = "main.lambda_handler"
  runtime          = "python3.8"
  memory_size      = 128
  timeout          = 300

  environment {
    variables = {
      PYTHONPATH               = "./dist-packages"
      PARAM_ACTION             = var.action
      PARAM_RESOURCE_TAG_KEY   = var.lookup_resource_tag.key
      PARAM_RESOURCE_TAG_VALUE = var.lookup_resource_tag.value
      PARAM_AWS_REGIONS        = var.lookup_resource_regions == null ? data.aws_region.this.name : join(",", var.lookup_resource_regions)
    }
  }
}