variable "stage"       { type = string }
variable "servicename" { type = string }
variable "tags"        { type = map(string) }

variable "vpc_id"              { type = string }
variable "public_subnets"      { type = list(string) }
variable "target_instance_ids" { type = list(string) }
variable "app_port"            { type = number }
variable "vpc_cidr"            { type = string }
variable "acm_certificate_arn" { type = string }
variable "domain_name"         { type = string }
