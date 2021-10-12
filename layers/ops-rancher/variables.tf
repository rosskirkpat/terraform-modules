variable "name" {
  description = "Environment name"
}

variable "region" {
  description = "AWS region to manage resources"
}

variable "monitoring-enabled" {
  description = "Enable monitoring"
  default     = true
}

variable "monitoring-ver" {
  description = "Monitoring chart version to deploy - needs to be null to deploy 0.2.0 or higher"
  default     = null
}

variable "monitoring-feature" {
  description = "Monitoring feature to deploy - relates to monitoring v1/v2"
  default     = "1"
}

variable "prometheus-retention" {
  description = "Retention for prometheus in hours"
  default     = "720h"
}

variable "prometheus-memory-limit" {
  description = "Memory limit for Prometheus in MB"
  default     = "3192"
}

variable "prometheus-volume-size" {
  description = "Persistent Volume size for Prometheus in GB"
  default     = "50"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}