########################
# CloudWatch Metrics Filter and Alarm
########################

# IAM Policy Change Detection
resource "aws_cloudwatch_log_metric_filter" "iam_policy_change_filter" {
  name           = "${var.common.env}-IAMPolicyChangeFilter"
  pattern        = <<EOT
  {($.eventName = DeleteGroupPolicy)||
  ($.eventName = DeleteRolePolicy)||
  ($.eventName = DeleteUserPolicy)||
  ($.eventName = PutGroupPolicy)||
  ($.eventName = PutRolePolicy)||
  ($.eventName = PutUserPolicy)||
  ($.eventName = CreatePolicy)||
  ($.eventName = DeletePolicy)||
  ($.eventName = CreatePolicyVersion)||
  ($.eventName = DeletePolicyVersion)||
  ($.eventName = AttachRolePolicy)||
  ($.eventName = DetachRolePolicy)||
  ($.eventName = AttachUserPolicy)||
  ($.eventName = DetachUserPolicy)||
  ($.eventName = AttachGroupPolicy)||
  ($.eventName = DetachGroupPolicy)}
  EOT
  log_group_name = var.cloudtrail.log_group_name
  metric_transformation {
    namespace = "CloudTrailMetrics"
    name      = "IAMPolicyEventCount"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "iam_policy_change_alarm" {
  alarm_name          = "${var.common.env}-IAMPolicyChangeAlarm"
  namespace           = aws_cloudwatch_log_metric_filter.iam_policy_change_filter.metric_transformation[0].namespace
  metric_name         = aws_cloudwatch_log_metric_filter.iam_policy_change_filter.metric_transformation[0].name
  period              = "300"
  statistic           = "Sum"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  threshold           = "1"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  alarm_description   = "IAM Configuration changes detected!"
  alarm_actions       = [aws_sns_topic.main.arn]
}

# New AccessKey Creation Detection
resource "aws_cloudwatch_log_metric_filter" "new_access_key_created_filter" {
  name           = "${var.common.env}-NewAccessKeyCreatedFilter"
  pattern        = <<EOT
  {($.eventName = CreateAccessKey)}
  EOT
  log_group_name = var.cloudtrail.log_group_name
  metric_transformation {
    namespace = "CloudTrailMetrics"
    name      = "NewAccessKeyCreatedEventCount"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "new_access_key_created_alarm" {
  alarm_name          = "${var.common.env}-NewAccessKeyCreatedAlarm"
  namespace           = aws_cloudwatch_log_metric_filter.new_access_key_created_filter.metric_transformation[0].namespace
  metric_name         = aws_cloudwatch_log_metric_filter.new_access_key_created_filter.metric_transformation[0].name
  period              = "300"
  statistic           = "Sum"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  threshold           = "1"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  alarm_description   = "Warning: New IAM access Key was created. Please be sure this action was neccessary."
  alarm_actions       = [aws_sns_topic.main.arn]
}

# Root User Activity Detection
resource "aws_cloudwatch_log_metric_filter" "root_user_activity_filter" {
  name           = "${var.common.env}-RootUserActivityFilter"
  pattern        = <<EOT
  {$.userIdentity.type = "Root" && 
  $.userIdentity.invokedBy NOT EXISTS && 
  $.eventType != "AwsServiceEvent"}
  EOT
  log_group_name = var.cloudtrail.log_group_name
  metric_transformation {
    namespace = "CloudTrailMetrics"
    name      = "RootUserActivityEventCount"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "root_user_activity_alarm" {
  alarm_name          = "${var.common.env}-RootUserActivityAlarm"
  namespace           = aws_cloudwatch_log_metric_filter.root_user_activity_filter.metric_transformation[0].namespace
  metric_name         = aws_cloudwatch_log_metric_filter.root_user_activity_filter.metric_transformation[0].name
  period              = "300"
  statistic           = "Sum"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  threshold           = "1"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  alarm_description   = "Root user activity detected!"
  alarm_actions       = [aws_sns_topic.main.arn]
}

########################
# EventBridge
########################

# Define EventBridge Rule (SgChangeEventRule)
resource "aws_cloudwatch_event_rule" "sg_change_event_rule" {
  name          = "${var.common.env}-SgChangeEventRule"
  description   = "Notify to create, update or delete a Security Group."
  event_pattern = <<EOT
  {
    "source": ["aws.ec2"],
    "detail-type": ["AWS API Call via CloudTrail"],
    "detail": {
      "eventSource": ["ec2.amazonaws.com"],
      "eventName": [
        "AuthorizeSecurityGroupIngress", 
        "AuthorizeSecurityGroupEgress", 
        "RevokeSecurityGroupIngress", 
        "RevokeSecurityGroupEgress"
      ]
    }
  }
  EOT
}

resource "aws_cloudwatch_event_target" "sg_change_event_rule" {
  rule      = aws_cloudwatch_event_rule.sg_change_event_rule.name
  target_id = "SgChangeTarget"
  arn       = aws_sns_topic.main.arn
}

# Define EventBridge Rule (NACLChangeEventRule​)
resource "aws_cloudwatch_event_rule" "nacl_change_event_rule" {
  name          = "${var.common.env}-NACLChangeEventRule"
  description   = "Notify to create, update or delete a Network ACL."
  event_pattern = <<EOT
  {
    "source": ["aws.ec2"],
    "detail-type": ["AWS API Call via CloudTrail"],
    "detail": {
      "eventSource": ["ec2.amazonaws.com"],
      "eventName": [
        "CreateNetworkAcl", 
        "CreateNetworkAclEntry", 
        "DeleteNetworkAcl", 
        "DeleteNetworkAclEntry", 
        "ReplaceNetworkAclAssociation", 
        "ReplaceNetworkAclEntry"
      ]
    }
  }
  EOT
}

resource "aws_cloudwatch_event_target" "nacl_change_event_rule" {
  rule      = aws_cloudwatch_event_rule.nacl_change_event_rule.name
  target_id = "NACLChangeTarget"
  arn       = aws_sns_topic.main.arn
}

# Define EventBridge Rule (CloudTrailChangeEventRule​)
resource "aws_cloudwatch_event_rule" "cloudtrail_change_event_rule" {
  name          = "${var.common.env}-CloudTrailChangeEventRule"
  description   = "Notify to change on CloudTrail log configuration."
  event_pattern = <<EOT
  {
    "detail-type": ["AWS API Call via CloudTrail"],
    "detail": {
      "eventSource": ["cloudtrail.amazonaws.com"],
      "eventName": [
        "StopLogging", 
        "DeleteTrail", 
        "UpdateTrail"
      ]
    }
  }
  EOT
}

resource "aws_cloudwatch_event_target" "cloudtrail_change_event_rule" {
  rule      = aws_cloudwatch_event_rule.cloudtrail_change_event_rule.name
  target_id = "CloudTrailChangeTarget"
  arn       = aws_sns_topic.main.arn
}

########################
# SNS
########################

# Define SNS Topic
resource "aws_sns_topic" "main" {
  name = "${var.common.env}-sns-topic"
  tags = {
    Name = "${var.common.env}-sns-topic"
  }
}

# Define SNS Topic Subscription
resource "aws_sns_topic_subscription" "main" {
  for_each  = toset(var.target.email_addresses)
  topic_arn = aws_sns_topic.main.arn
  protocol  = "email"
  endpoint  = each.key
}

# Define SNS Topic Policy
data "aws_iam_policy_document" "sns-topic" {
  statement {
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.main.arn]
    effect    = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com", "cloudwatch.amazonaws.com"]
    }
  }
}

# Associate SNS Topic Policy
resource "aws_sns_topic_policy" "main" {
  arn    = aws_sns_topic.main.arn
  policy = data.aws_iam_policy_document.sns-topic.json
}
