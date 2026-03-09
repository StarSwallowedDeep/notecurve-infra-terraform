#Comm TAG
variable "tags" {
  type = map(string)
  default = {
    Environment = "dev"
    Owner       = "test"
  }
}
variable "stage" {
  type    = string
  default = "dev"
}
variable "servicename" {
  type    = string
  default = "myapp"
}

#VPC
variable "az" {
  type    = string
  default = "ap-northeast-2a"
}
variable "vpc_ip_range" {
  type    = string
  default = "10.1.0.0/16"
}
variable "subnet_public_az1" {
  type    = string
  default = "10.1.1.0/24"
}
