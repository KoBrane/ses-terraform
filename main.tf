provider "aws" {
region = "us-east-1"
}



terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}



// SES Domain Identity Verification
resource "aws_ses_domain_identity" "this" {
  domain = var.domain
}

// Route53 Zone
data "aws_route53_zone" "this" {
  name = var.domain
}

resource "aws_ses_domain_dkim" "this" {
  domain = aws_ses_domain_identity.this.domain
}

resource "aws_route53_record" "this_dkim" {
  count   = 3
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "${aws_ses_domain_dkim.this.dkim_tokens[count.index]}._domainkey"
  type    = "CNAME"
  ttl     = "600"
  records = ["${aws_ses_domain_dkim.this.dkim_tokens[count.index]}.dkim.amazonses.com"]
}
// Verify domain identity

resource "aws_ses_domain_identity_verification" "this" {
  domain = aws_ses_domain_identity.this.id

  depends_on = [
    aws_route53_record.this_dkim
  ]
}

resource "aws_route53_record" "this_mx" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = ""
  type    = "MX"
  ttl     = "3600"
  records = ["10 inbound-smtp.${var.region}.amazonaws.com"]

}


//SES Receipt Rule Set
resource "aws_ses_receipt_rule_set" "this" {
  rule_set_name = var.rule_set_name
}

# Add a header to the email and store it in S3
resource "aws_ses_receipt_rule" "this" {
  name          = var.receipt_rule_name
  rule_set_name = aws_ses_receipt_rule_set.this.rule_set_name
  recipients    = var.recipients_email
  enabled       = var.rule_enabled
  scan_enabled  = var.scan_enabled

  add_header_action {
    header_name  = "Custom-Header"
    header_value = "Added by SES"
    position     = 1
  }

  # Dynamic block for S3 action
  dynamic "s3_action" {
    for_each = var.enable_s3 ? [1] : []
    content {
      bucket_name       = var.bucket_name
      object_key_prefix = "incoming-emails/"
      position          = 2
    }
  }
}


resource "aws_ses_active_receipt_rule_set" "this" {
  rule_set_name = aws_ses_receipt_rule_set.this.rule_set_name
}

module "s3_email_receipt_store" {
  source = "./modules/s3mailbox"

  count         = var.enable_s3 ? 1 : 0
  bucket_name   = var.bucket_name
  filter_prefix = var.filter_prefix
}

module "lambda_s3_trigger" {
  source = "./modules/lambda"

  count                  = var.enable_s3 ? 1 : 0
  policy_attachment_name = var.policy_attachment_name
  filter_prefix          = var.filter_prefix
  bucket_name            = var.bucket_name
  bucket_arn             = "arn:aws:s3:::${var.bucket_name}"
  function_prefix        = var.folder_name
}