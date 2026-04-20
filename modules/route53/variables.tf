variable "tags"          { type = map(string) }
variable "domain_name"   { type = string }
variable "hosted_zone_id" { type = string }

variable "seoul_alb_dns"     { type = string }
variable "seoul_alb_zone_id" { type = string }
variable "tokyo_alb_dns"     { type = string }
variable "tokyo_alb_zone_id" { type = string }
