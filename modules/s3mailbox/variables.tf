variable "bucket_name" {
  description = "Name of the bucket to receive and convert SES emails"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "bucket_ownership_controls" {
  description = "S3 Bucket Ownership Controls"
  type        = string
  default     = "BucketOwnerPreferred"
}

variable "lifecycle_expiration_period" {
  description = "Lifecyle expiration period for incoming emails"
  type        = number
  default     = 7
}

variable "filter_prefix" {
  description = "Filter prefix for incoming emails"
  type        = string
  default     = "incoming-emails/"
}