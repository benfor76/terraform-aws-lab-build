#
variable "rhel_version" {
  description = "RHEL Version"
  default     = "RHEL9"
}

variable "lookup_map" {
  type = map(string)
  default = {
    "RHEL9" = "RHEL-9.6"
  }
}

variable "instance_name_convention" {
  description = "VM instance name convention"
  default     = "aap25"
}

variable "number_of_instances" {
  description = "VM number of instances"
  type        = number
  default     = 8
}