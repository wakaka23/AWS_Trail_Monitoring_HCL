########################
# S3 Bucket
########################

# Define S3 Bucket for CloudTrail
resource "aws_s3_bucket" "cloudtrail" {
  bucket = var.bucket.bucket_name_for_TrailLog
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.bucket

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Define S3 Bucket Policy for CloudTrail
resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.bucket
  policy = data.aws_iam_policy_document.cloudtrail.json
}

data "aws_iam_policy_document" "cloudtrail" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:${var.common.region}:${var.common.account_id}:trail/trail-monitoring-cloudtrail"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${var.common.account_id}/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:aws:cloudtrail:${var.common.region}:${var.common.account_id}:trail/trail-monitoring-cloudtrail"]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

########################
# CloudWatch Logs
########################

# Define CloudWatch Log Group for CloudTrail
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "${var.common.env}-cloudtrail-loggroup"
  retention_in_days = 365
}

########################
# CloudTrail
########################

# Define CloudTrail trail
resource "aws_cloudtrail" "main" {
  name                          = "${var.common.env}-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.bucket
  include_global_service_events = true
  enable_log_file_validation    = true
  is_multi_region_trail         = true
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail.arn
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  depends_on                    = [aws_s3_bucket_policy.cloudtrail]
}

# Define IAM role for CloudTrail
resource "aws_iam_role" "cloudtrail" {
  name               = "${var.common.env}-role-for-cloudtrail"
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_trust_policy.json
}

# Define trust policy for CloudTrail
data "aws_iam_policy_document" "cloudtrail_trust_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Define IAM policy for CloudTrail
resource "aws_iam_policy" "cloudtrail_policy" {
  name        = "${var.common.env}-policy-for-cloudtrail"
  description = "Policy for CloudTrail"
  policy      = data.aws_iam_policy_document.cloudtrail_policy.json
}

data "aws_iam_policy_document" "cloudtrail_policy" {
  statement {
    sid       = "CloudTrailCreateLogStream"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream"]
    resources = ["${aws_cloudwatch_log_group.cloudtrail.arn}:*"]
  }

  statement {
    sid       = "CloudTrailPutLogEvents"
    effect    = "Allow"
    actions   = ["logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.cloudtrail.arn}:*"]
  }
}

# Attach IAM policy to IAM role
resource "aws_iam_role_policy_attachments_exclusive" "cloudtrail" {
  role_name = aws_iam_role.cloudtrail.name
  policy_arns = [
    aws_iam_policy.cloudtrail_policy.arn
  ]
}
