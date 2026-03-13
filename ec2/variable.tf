# variable "stage" {
#   type    = string
#   default = "dev"
# }

variable "servicename" {
  type    = string
  default = "myapp"
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "dev"
    Owner       = "test"
  }
}

variable "ami" {
  type    = string
  default = "ami-0130d8d35bcd2d433"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "sg_ec2_ids" {
  type    = list(any)
  default = []
}

variable "subnet_id" {
  type = string
}

variable "user_data" {
  type    = string
  default = ""
}

variable "associate_public_ip_address" {
  type    = bool
  default = true
}

variable "isPortForwarding" {
  type    = bool
  default = false
}

variable "key_name" {
  type    = string
  default = "0000-keypair"
}

variable "ssh_allow_comm_list" {
  type    = list(any)
  default = [] # 본인 IP로 변경 필요 예: ["x.x.x.x/32"]
}
