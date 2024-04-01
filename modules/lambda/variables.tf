variable "bucket_name" {
  description = "Name of s3 bucket"
  type        = string
}

variable "bucket_arn" {
  description = "ARN of the s3 bucket for incoming emails"
  type        = string
}

variable "filter_prefix" {
  description = "Filter prefix for incoming emails"
  type        = string
}

variable "folder_name" {
  description = "Folder name for the s3 object"
  type        = string
}

variable "lambda_handler_name" {
  description = "Name for the Lambda handler"
  type        = string
  default     = "s3_lambda.lambda_handler"
}

variable "function_prefix" {
  description = "Function prefix"
  type        = string
  default     = "processed-emails"
}


variable "policy_attachment_name" {
  description = "Name of the policy attchment to the Lambda"
  type        = string
  default     = "lambda-execution-for-s3"
}

