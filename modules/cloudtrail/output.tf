########################
# CloudWatch Logs
########################

output "log_group_name" {
  value = aws_cloudwatch_log_group.cloudtrail.name
}
