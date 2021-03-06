provider "aws" {
  access_key                  = "mock_access_key"
  region                      = "us-east-1"
  s3_use_path_style           = true
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2     = "http://localhost:4566"
    route53 = "http://localhost:4566"
    s3      = "http://localhost:4566"
  }
}
