output "id" {
    description = "ID that identifies the s3"
    value = try(aws_s3_bucket.this.id, null)
}