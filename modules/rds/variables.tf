variable "stage"       { type = string }
variable "servicename" { type = string }
variable "tags"        { type = map(string) }

# DB 설정
variable "database_name"    { type = string }
variable "master_username"  { type = string }
variable "master_password"  {
  type      = string
  sensitive = true
}
variable "instance_class" {
  type    = string
  default = "db.r6g.large"
}

# 서울 (Primary)
variable "primary_vpc_id"        { type = string }
variable "primary_vpc_cidr"      { type = string }
variable "primary_db_subnet_ids" { type = list(string) }

# 도쿄 (Secondary)
variable "secondary_vpc_id"        { type = string }
variable "secondary_vpc_cidr"      { type = string }
variable "secondary_db_subnet_ids" { type = list(string) }
