output "network-vpc" {
  value = aws_vpc.aws-vpc
}

output "public-az1" {
  value = aws_subnet.public-az1
}

output "vpc_id" {
  value = aws_vpc.aws-vpc.id
}

output "vpc_cidr" {
  value = aws_vpc.aws-vpc.cidr_block
}
