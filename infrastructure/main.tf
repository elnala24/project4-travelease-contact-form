# ==========================================
# S3 Bucket - Static Website
# ==========================================
resource "aws_s3_bucket" "travelease_bucket" {
  bucket = "travelease-contact-form-${var.project_name}"
}

resource "aws_s3_bucket_website_configuration" "site_configuration" {
  bucket = aws_s3_bucket.travelease_bucket.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.travelease_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# ==========================================
# S3 Bucket Policy
# ==========================================
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.travelease_bucket.id

  depends_on = [aws_s3_bucket_public_access_block.public_access_block]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.travelease_bucket.arn}/*"
      }
    ]
  })
}

# ==========================================
# DynamoDB Table
# ==========================================
resource "aws_dynamodb_table" "dynamodb_table" {
  name         = "${var.project_name}-inquiries"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "inquiry_id"

  attribute {
    name = "inquiry_id"
    type = "S"
  }
}

# ==========================================
# IAM Role for Lambda
# ==========================================
resource "aws_iam_role" "travelease_iam_role" {
  name = "${var.project_name}-lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# ==========================================
# IAM Policy for Lambda
# ==========================================
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.travelease_iam_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Sid    = "DynamoDB"
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem"
        ]
        Resource = aws_dynamodb_table.dynamodb_table.arn
      },
      {
        Sid    = "SES"
        Effect = "Allow"
        Action = [
          "ses:SendEmail"
        ]
        Resource = "*"
      }
    ]
  })
}

# ==========================================
# Lambda Function
# ==========================================
resource "aws_lambda_function" "lambda_function" {
  filename         = "lambda.zip"
  source_code_hash = filebase64sha256("lambda.zip")
  function_name    = "${var.project_name}-contact-handler"
  role             = aws_iam_role.travelease_iam_role.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"

  environment {
    variables = {
      TABLE_NAME     = aws_dynamodb_table.dynamodb_table.name
      SENDER_EMAIL   = var.sender_email
      BUSINESS_EMAIL = var.business_email
    }
  }
}

# ==========================================
# API Gateway - REST API
# ==========================================
resource "aws_api_gateway_rest_api" "rest_api" {
  name        = "${var.project_name}-api"
  description = "Travelease Contact Form API"
}

# ==========================================
# API Gateway - Resouce (/submit)
# ==========================================
resource "aws_api_gateway_resource" "api_resource" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "submit"
}

# ==========================================
# API Gateway - POST Method
# ==========================================
resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.api_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# ==========================================
# API Gateway: Lambda Integration
# ==========================================
resource "aws_api_gateway_integration" "integrate" {
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_resource.api_resource.id
  http_method             = "POST"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_function.invoke_arn
}

# ==========================================
# API Gateway: Lambda Permission
# ==========================================
resource "aws_lambda_permission" "invoke_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.id
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*/*"
}

# ==========================================
# CORS - Options Method (Since website (S3) and API (API Gateway) are on different domains, we need to enable CORS)
# ==========================================
resource "aws_api_gateway_method" "options" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.api_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# ==========================================
# CORS - MOCK integration - it doesn't call Lambda, just returns CORS headers.
# ==========================================
resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.api_resource.id
  http_method = "OPTIONS"
  type        = "MOCK"

  depends_on = [aws_api_gateway_method.options]

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# ==========================================
# CORS - Method Response (defines allowed response headers)
# ==========================================
resource "aws_api_gateway_method_response" "options_response" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.api_resource.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# ==========================================
# CORS - OPTIONS Integration Response
# ==========================================
resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.api_resource.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = aws_api_gateway_method_response.options_response.status_code

  depends_on = [aws_api_gateway_integration.options_integration]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# ==========================================
# Deploy the API - Deployment
# ==========================================
resource "aws_api_gateway_deployment" "deploy" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id

  triggers = {
    redeployment = timestamp()
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.integrate,
    aws_api_gateway_integration.options_integration
  ]
}

# ==========================================
# Deploy the API - Stage
# ==========================================
resource "aws_api_gateway_stage" "prod" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  deployment_id = aws_api_gateway_deployment.deploy.id
  stage_name    = "prod"
}






