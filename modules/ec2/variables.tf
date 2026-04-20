variable "stage"       { type = string }
variable "servicename" { type = string }
variable "tags"        { type = map(string) }

variable "ami"           { type = string }
variable "instance_type" { type = string }
variable "subnet_id"     { type = string }
variable "key_name"      { type = string }
variable "vpc_id"        { type = string }

variable "associate_public_ip_address" {
  type    = bool
  default = false
}

variable "is_port_forwarding" {
  type    = bool
  default = false
}

variable "volume_size" {
  type    = number
  default = 20
}

variable "ssh_allow_cidrs" {
  type    = list(string)
  default = []
}

variable "extra_sg_ids" {
  type    = list(string)
  default = []
}

variable "ingress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr        = string
    description = string
  }))
  default = []
}

variable "user_data" {
  type    = string
  default = null
}
