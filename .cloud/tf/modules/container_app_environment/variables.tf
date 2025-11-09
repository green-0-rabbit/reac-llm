variable "environment" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "infrastructure_subnet_id" { type = string }
variable "log_analytics_workspace_id" {
  type    = string
  default = ""
}
variable "create_log_analytics" {
  type    = bool
  default = true
}
variable "internal_only" {
  type    = bool
  default = true
}
variable "workload_profile" {
  type = object({
    name                  = optional(string)
    workload_profile_type = optional(string)
    minimum_count         = optional(number)
    maximum_count         = optional(number)
  })
  default = null
}
variable "tags" {
  type    = map(string)
  default = {}
}
