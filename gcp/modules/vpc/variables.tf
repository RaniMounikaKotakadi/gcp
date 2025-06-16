variable "vpc_name" {}
variable "subnet_name" {}
variable "subnet_cidr" {}
variable "connector_name" {}
variable "region" {}
variable "connector_cidr" {
  description = "IP CIDR range used for the VPC connector"
  type        = string
}