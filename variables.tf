variable "domain" {
  description = "Domain identity to be verified"
  type        = string
}

variable "rule_set_name" {
  description = "Name for SES receipt rule set"
  type        = string
}

variable "receipt_rule_name" {
  description = "The name of the SES receipt rule"
  type        = string
}

variable "rule_enabled" {
  description = "The rule will be enabled if true"
  type        = bool
  default     = true
}

variable "scan_enabled" {
  description = "If true, it will scan all incoming emails for spam and viruses enabled"
  type        = bool
  default     = true
}

variable "region" {
  description = "AWS region to deploy the MX record"
  type        = string
  default     = "us-east-1"
}

variable "recipients_email" {
  description = "A list of email address to be used as receipient email"
  type        = list(string)
  default     = []
}

variable "bucket_name" {
  description = "Name of the bucket to receive the email from SES"
  type        = string
}

variable "enable_s3" {
  description = "This enables the creation of s3 and s3 email receipt rule for ses"
  type        = bool
  default     = true
}

variable "filter_prefix" {
  description = "Lambda filter prefix for incoming emails"
  type        = string
  default     = "incoming-emails/"
}

variable "folder_name" {
  description = "Folder name for the s3 object"
  type        = string
  default     = "processed-emails"
}

variable "policy_attachment_name" {
  description = "Name of the policy attchment to the Lambda"
  type        = string
  default     = "lambda-execution-for-s3"
}
