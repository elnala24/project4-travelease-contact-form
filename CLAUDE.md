# TravelEase Contact Form

## Project Overview
TravelEase is a serverless contact form application for a travel agency. Users submit a travel inquiry through a static website hosted on S3. The form hits an API Gateway endpoint, triggers a Lambda function that stores the data in DynamoDB and sends emails via SES (confirmation to customer + notification to business).

## Tech Stack
- **Infrastructure as Code**: Terraform (HCL)
- **Cloud Provider**: AWS (us-west-1)
- **AWS Services**: S3, API Gateway (REST), Lambda (Node.js 18.x), DynamoDB, SES
- **Frontend**: Static HTML/CSS/JavaScript (hosted on S3)
- **Version Control**: Git/GitHub

## Project Structure
```
project4-travelease/
├── architecture/            # Architecture diagrams
├── frontend/                # Static website files (HTML, CSS, JS)
├── infrastructure/
│   ├── main.tf              # All AWS resource definitions
│   ├── providers.tf         # AWS provider configuration
│   ├── variables.tf         # Variable declarations
│   ├── terraform.tfvars     # Variable values (DO NOT commit)
│   ├── outputs.tf           # Output values (api_url, website_url)
│   └── lambda.zip           # Zipped Lambda function for deployment
├── lambda/
│   └── index.js             # Lambda function (Node.js)
└── CLAUDE.md                # This file
```

## Current Status
- Infrastructure deployed (19 resources via terraform apply)
- Next steps: Verify SES email, build frontend, upload to S3, test

## Key Commands
```bash
# Navigate to infrastructure
cd infrastructure/

# Terraform workflow
terraform init
terraform plan
terraform apply
terraform destroy

# Zip Lambda for deployment
cd ../lambda && zip -r ../infrastructure/lambda.zip index.js && cd ../infrastructure
```

## Important Rules
- NEVER use wildcard (*) IAM actions — always use least-privilege
- ALWAYS configure CORS in BOTH API Gateway AND Lambda response headers
- All resources are in us-west-1
- terraform.tfvars contains sensitive values — NEVER commit to git
- Lambda uses Node.js 18.x runtime
- SES is in sandbox mode — only verified emails can send/receive
- Keep costs under $0.20/month — this is a portfolio project
- Always zip Lambda code before deploying

## Known Issues & Solutions
- CORS errors: Must set CORS headers in API Gateway AND Lambda responses
- Lambda deployment: Must zip index.js before terraform apply picks it up
- SES sandbox: Both sender and recipient emails must be verified
- API Gateway: Changes require redeployment to a stage

## Code Conventions
- Terraform: snake_case for resource names, descriptive naming, tag all resources
- JavaScript: Use AWS SDK v3 (@aws-sdk), include error handling, return proper HTTP status codes
- Always include meaningful comments explaining WHY, not just WHAT