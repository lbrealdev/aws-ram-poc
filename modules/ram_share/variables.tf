variable "name" {
  type        = string
  description = "Name of the resource share."
}

variable "allow_external_principals" {
  type        = bool
  description = "Allow principals outside the organization."
  default     = false
}

variable "permission_arns" {
  type        = list(string)
  description = "Managed permission ARNs to associate with the share."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags for the resource share."
  default     = {}
}
