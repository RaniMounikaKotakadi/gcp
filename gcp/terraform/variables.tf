variable "project_id" {}
variable "region" {}
variable "is_public" {
  description = "If true, allows allUsers to invoke the function. If false, use service account."
  type        = bool
  default     = false
}
variable "public_member" {
  description = "IAM member to allow public or restricted access"
  type        = string
}
variable "billing_account" {
  description = "The GCP Billing Account ID"
  type        = string
}
variable "project_name" {
  type = string
}

variable "env" {
  type = string
}