output "application_name" { value = aws_kinesisanalyticsv2_application.this.name }
output "application_arn" { value = aws_kinesisanalyticsv2_application.this.arn }
output "execution_role_arn" { value = aws_iam_role.flink.arn }
output "log_group_name" { value = aws_cloudwatch_log_group.flink.name }
