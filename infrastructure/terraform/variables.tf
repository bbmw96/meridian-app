variable "region" {
  description = "AWS region for all MERIDIAN infrastructure. Defaults to eu-west-2 (London) to minimise latency for UK operations."
  type        = string
  default     = "eu-west-2"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.region))
    error_message = "Region must be a valid AWS region identifier such as eu-west-2 or us-east-1."
  }
}

variable "cluster_name" {
  description = "Name of the EKS cluster. Used as a reference across all Kubernetes resources."
  type        = string
  default     = "meridian-production"

  validation {
    condition     = length(var.cluster_name) >= 3 && length(var.cluster_name) <= 100
    error_message = "Cluster name must be between 3 and 100 characters."
  }
}

variable "db_password" {
  description = "Master password for the MERIDIAN RDS PostgreSQL instance. Must be at least 16 characters and contain a mix of character types."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 16
    error_message = "Database password must be at least 16 characters long."
  }
}

variable "redis_auth_token" {
  description = "Authentication token for the ElastiCache Redis replication group. Must be at least 16 characters."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.redis_auth_token) >= 16
    error_message = "Redis auth token must be at least 16 characters long."
  }
}

variable "environment" {
  description = "Deployment environment. Controls resource naming, tagging, and certain configuration defaults."
  type        = string
  default     = "production"

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be one of: development, staging, production."
  }
}
