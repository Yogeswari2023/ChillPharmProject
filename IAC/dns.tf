data "aws_route53_zone" "zone" {
  name = "${var.dns_zone_name}."
  private_zone = false
}

resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "${lookup(var.subdomain, terraform.workspace, "default")}.${data.aws_route53_zone.zone.name}"
  type    = "CNAME"
  ttl     = "300"

  records = [aws_lb.api.dns_name]
}

resource "aws_acm_certificate" "cert" {
  domain_name       = aws_route53_record.app.fqdn
  validation_method = "DNS"


  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_route53_record" "cert_validation" {
  for_each = aws_route53_record.cert_validation
  name    = aws_acm_certificate.cert[each.value].domain_validation_options[0].resource_record_name
  type    = aws_acm_certificate.cert[each.value].domain_validation_options[0].resource_record_type
  zone_id = data.aws_route53_zone.zone.zone_id

  records = [aws_acm_certificate.cert[each.value].domain_validation_options[0].resource_record_value]
  ttl     = "60"
}


resource "aws_acm_certificate_validation" "cert" {
  for_each                 = aws_route53_record.cert_validation
  certificate_arn         = aws_acm_certificate.cert[each.key].arn
  validation_record_fqdns = [each.value.fqdn]
}