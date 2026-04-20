output "alb_arn"        { value = aws_lb.this.arn }
output "alb_dns_name"   { value = aws_lb.this.dns_name }
output "alb_zone_id"    { value = aws_lb.this.zone_id }
output "alb_arn_suffix" { value = aws_lb.this.arn_suffix }
output "tg_arn"         { value = aws_lb_target_group.app.arn }
output "admin_tg_arn"   { value = aws_lb_target_group.admin.arn }
