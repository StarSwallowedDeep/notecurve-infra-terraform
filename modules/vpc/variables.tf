variable "region"      { type = string }
variable "stage"       { type = string }
variable "servicename" { type = string }
variable "tags"        { type = map(string) }

variable "vpc_cidr"          { type = string }
variable "public_subnet_az1" { type = string }
variable "public_subnet_az2" { type = string }
variable "private_app_az1"   { type = string }
variable "private_app_az2"   { type = string }
variable "private_db_az1"    { type = string }
variable "private_db_az2"    { type = string }
variable "az1"               { type = string }
variable "az2"               { type = string }
