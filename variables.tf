variable "subnet_ids_peer" {
  description = "Subnet IDs (Peer)"
  type        = list(any)
  default     = []
  validation {
    condition     = length(var.subnet_ids_peer) > 0
    error_message = "Subnet IDs (Peer) not Specified."
  }
}

variable "subnet_ids_source" {
  description = "Subnet IDs (Source)"
  type        = list(any)
  default     = []
  validation {
    condition     = length(var.subnet_ids_source) > 0
    error_message = "Subnet IDs (Source) not Specified."
  }
}

variable "vpc_peer_id" {
  description = "VPC (Peer): ID"
  type        = string
  default     = ""
  validation {
    condition     = var.vpc_peer_id != ""
    error_message = "VPC ID (Peer) not Specified."
  }
}

variable "vpc_source_id" {
  description = "VPC (Source): ID"
  type        = string
  default     = ""
  validation {
    condition     = var.vpc_source_id != ""
    error_message = "VPC ID (Source) not Specified."
  }
}
