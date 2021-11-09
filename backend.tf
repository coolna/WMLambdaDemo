# Build an S3 bucket to store TF state
resource "aws_s3_bucket" "state_bucket" {
  bucket = "terraform-remote-state-storage-s3-lambda"

  # Tells AWS to encrypt the S3 bucket at rest by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  # Prevents Terraform from destroying or replacing this object - a great safety mechanism
#   lifecycle {
#     prevent_destroy = true
#   }

  # Tells AWS to keep a version history of the state file
  versioning {
    enabled = true
  }

  tags = {
    Terraform = "true"
  }
}

# Build a DynamoDB to use for terraform state locking
resource "aws_dynamodb_table" "tf_lock_state" {
  name = "aws-locks"

  # Pay per request is cheaper for low-i/o applications, like our TF lock state
  billing_mode = "PAY_PER_REQUEST"

  # Hash key is required, and must be an attribute
  hash_key = "LockID"

  # Attribute LockID is required for TF to use this table for lock state
  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name    = "aws-locks"
    BuiltBy = "Terraform"
  }
}


terraform {
  required_version = ">=0.12.13"
  backend "s3" {
   bucket         = "terraform-remote-state-storage-s3-lambda"
   key            = "terraform.tfstate"
   region         = "eu-central-1"
   dynamodb_table = "aws-locks"
   encrypt        = true
  }
}
