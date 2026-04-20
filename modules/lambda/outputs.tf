output "lambda_arn"       { value = aws_lambda_function.dr.arn }
output "sns_topic_arn"    { value = aws_sns_topic.dr_alert.arn }
