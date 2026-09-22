variable "aws_region" {
  type        = string
  description = "AWS Region for the RAM resource share (must match the shared resource Region)."
}

variable "share_name" {
  type        = string
  description = "Name of the AWS RAM resource share."
}

variable "allow_external_principals" {
  type        = bool
  description = "Whether principals outside the organization may be associated. Keep false for org-only resource types (e.g. subnets)."
  default     = false
}

variable "permission_arns" {
  type        = list(string)
  description = "Optional managed permission ARNs (one per resource type on the share). Empty => RAM default permissions."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Extra tags for the resource share."
  default     = {}
}
