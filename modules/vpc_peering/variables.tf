variable "tags" { type = map(string) }

variable "requester_vpc_id"           { type = string }
variable "requester_vpc_cidr"         { type = string }
variable "requester_private_rt_az1_id" { type = string }
variable "requester_private_rt_az2_id" { type = string }

variable "accepter_vpc_id"            { type = string }
variable "accepter_vpc_cidr"          { type = string }
variable "accepter_region"            { type = string }
variable "accepter_private_rt_az1_id" { type = string }
variable "accepter_private_rt_az2_id" { type = string }
