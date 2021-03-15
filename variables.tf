variable "schedule_expression" {
  type        = string
  description = "Define the schedule expression to trigger the lambda."
}

variable "name" {
  type        = string
  description = "The name of the lambda to create."
}

variable "tags" {
  default     = {}
  description = "Tags to associate to the lambda."
  type        = map(string)
}

variable "custom_iam_role_arn" {
  description = "A custom IAM role to execute the lambda. If not specified, a role will be created."
  type        = string
  default     = null
}

variable "action" {
  type        = string
  description = "The action which the lambda needs to perform."
  validation {
    condition     = contains(["start", "stop", "enable", "disable"], var.action)
    error_message = "Allowed values for action are \"start\", \"stop\", \"enable\" or \"disable\"."
  }
}

variable "lookup_resource_tag" {
  type        = object({ key = string, value = string })
  description = "The tag to use to search for EC2 instances."
}

variable "lookup_resource_regions" {
  description = "A list of regions in which the resources will be looked for. By default, use the current region."
  type        = list(string)
  default     = null
}