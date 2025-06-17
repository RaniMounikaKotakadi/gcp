variable "name" {}
variable "region" {}
variable "source_bucket" {}
variable "source_object" {}
variable "project_id" {}
variable "lb_invoker_sa_email" {}
variable "is_public" {
  description = "If true, allows allUsers to invoke the function. If false, use service account."
  type        = bool
  default     = false
}
variable "vpc_connector" {
  description = "The name of the VPC connector used for outbound access"
  type        = string
}
variable "public_member" {
  description = "Member to grant public or restricted access to Cloud Function (e.g. 'allUsers' or a service account)"
  type        = string
}

