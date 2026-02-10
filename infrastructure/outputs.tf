# ==========================================
# Outputs
# ==========================================

output "website_url" {
  value = aws_s3_bucket_website_configuration.site_configuration.website_endpoint
}

output "api_url" {
  value = "${aws_api_gateway_stage.prod.invoke_url}/submit"
}
