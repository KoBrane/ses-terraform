provider "aws" {
  region = "us-east-1"
}

resource "aws_ses_domain_identity" "this" {
  domain = "devsecopsdeployed.com"

}

data "aws_route53_zone" "this" {
  name = aws_ses_domain_identity.this.domain
}

resource "aws_ses_domain_dkim" "this" {
  domain = aws_ses_domain_identity.this.domain
}

resource "aws_route53_record" "dkim" {
  count   = var.deploy_dkim ? 3 : 0
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "${aws_ses_domain_dkim.this.domain}._domainkey.${data.aws_route53_zone.this.name}"
  type    = "CNAME"
  ttl     = "600"
  records = ["${aws_ses_domain_dkim.this.dkim_tokens[count.index]}.dkim.amazonses.com"]
}




variable "deploy_dkim" {
  description = "wheter to deploy or not"
  type        = bool
  default     = false
}

resource "aws_ses_domain_identity_verification" "identity_verification" {
  count  = var.enable_domain_verification ? 1 : 0
  domain = aws_ses_domain_identity.this.id

  depends_on = [aws_route53_record.dkim]
}

variable "enable_domain_verification" {
  description = "wheter to deploy or not"
  type        = bool
  default     = false
}

resource "aws_route53_record" "mx_record" {
  count   = var.enable_mx_record ? 1 : 0
  zone_id  = data.aws_route53_zone.this.id
  name    = ""
  type    = "MX"
  ttl     = "3600"
  records = ["10 inbound-smtp.us-east-1.amazonaws.com"]
}

variable "enable_mx_record" {
  description = "wheter to deploy or not"
  type        = bool
  default     = false
}