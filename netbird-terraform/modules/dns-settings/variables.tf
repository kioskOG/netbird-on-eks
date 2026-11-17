variable "disabled_management_groups" {
  description = "Groups whose DNS management is disabled"
  type        = list(string)
  default     = []
}
