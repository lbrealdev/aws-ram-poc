variable "resource_share_arn" {
  type        = string
  description = "ARN of the AWS RAM resource share."
}

variable "resource_arns" {
  type        = list(string)
  description = "Resource ARNs to associate (e.g. Advanced SSM parameter ARNs)."
  default     = []
}

variable "principals" {
  type        = list(string)
  description = "Principals to associate: AWS account ID, Organization ARN, OU ARN, or IAM role/user ARN (when the resource type allows)."
  default     = []
}
