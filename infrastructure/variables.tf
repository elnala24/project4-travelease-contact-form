variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-1"
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "project4-travelease"
}

variable "environment" {
  description = "Environment (dev, staging, production)"
  type        = string
  default     = "production"
}

variable "sender_email" {
  description = "Verified SES email for sending"
  type        = string
}

variable "business_email" {
  description = "Business email to receive notifications"
  type        = string
}
