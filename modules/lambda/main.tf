resource "aws_iam_role" "this" {
  name = "${var.function_prefix}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_iam_policy" "this" {
  name        = "${var.function_prefix}-policy"
  path        = "/"
  description = "IAM policy for Lambda email processing"

  policy = jsonencode(
    {
      Version : "2012-10-17",
      Statement : [
        {
          Effect : "Allow",
          Action : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          Resource : "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.this.function_name}:*"
        },
        {
          Effect : "Allow",
          Action : [
            "s3:GetObject",
            "s3:PutObject",
            "s3:PutObjectTagging",
            "s3:GetObjectTagging"
          ],
          Resource : "arn:aws:s3:::${var.bucket_name}/*"
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "lambda_execution_policy" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

resource "aws_lambda_function" "this" {
  filename         = data.archive_file.this.output_path
  source_code_hash = filebase64sha256(data.archive_file.this.output_path)
  function_name    = "${var.function_prefix}-lambda"
  role             = aws_iam_role.this.arn
  handler          = var.lambda_handler_name

  runtime = "python3.12"

  environment {
    variables = {
      PROCESSED_EMAILS_FOLDER = var.function_prefix
      MAIN_EMAILS_FOLDER      = var.filter_prefix
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_execution_policy
  ]
}

resource "aws_lambda_permission" "this" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "s3.amazonaws.com"

  source_arn = var.bucket_arn
}

resource "aws_s3_bucket_notification" "this" {
  bucket = var.bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.this.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.filter_prefix
  }
}

resource "data" "archive_file" {
  type        = "zip"
  source_dir  = "${path.module}/Functions"
  output_path = "./tmp/s3_lambda${formatdate("YYYYMMDDhhmm", timestamp())}.zip"
  excludes    = ["test_s3_lambda.py", "__pycache__", "*.zip", "*.pyc"]
}
