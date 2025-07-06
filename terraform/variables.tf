# Variable for GitHub Actions role ARN
variable "github_actions_role_arn" {
  description = "ARN of the GitHub Actions IAM role"
  type        = string
  default     = ""
}