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

variable "instance_names" {
  description = "List of unique names for AAP instances"
  type        = list(string)
  default     = ["aap25controller", "aap25gateway", "aap25pah", "aap25eda", "aap25pg", "aap25en", "test1node", "test2node"]
}