variable "project_id" {
  type        = string
  description = "Project ID for the VPC resources"
}

variable "region" {
  type        = string
  description = "Region for the subnetwork and connector"
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
}

variable "subnet_name" {
  type        = string
  description = "Name of the subnet"
}

variable "subnet_cidr" {
  type        = string
  description = "CIDR range for the subnet"
}

variable "connector_name" {
  type        = string
  description = "Name for the VPC connector"
}

variable "connector_cidr" {
  type        = string
  description = "CIDR range for the connector"
}

variable "env" {
  type = string
}

variable "project_name" {
  type = string
}