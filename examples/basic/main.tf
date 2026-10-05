# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Two existing VPCs in the same AWS account and Region, peered, with a route in one
# route table on each side.

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "requester_vpc_id" {
  description = "ID of the VPC that requests the peering connection, such as vpc-0123456789abcdef0"
  type        = string
}

variable "requester_route_table_id" {
  description = "ID of a route table in the requester VPC that gets a route to the accepter VPC"
  type        = string
}

variable "accepter_vpc_id" {
  description = "ID of the VPC that accepts the peering connection. Its CIDR block must not overlap the requester VPC's."
  type        = string
}

variable "accepter_route_table_id" {
  description = "ID of a route table in the accepter VPC that gets a route to the requester VPC"
  type        = string
}

module "vpc_peering" {
  source = "../../"

  # Both VPCs are in this provider's account, so the same provider is passed twice.
  providers = { aws = aws, aws.peer = aws }

  details = {
    scope       = "Example"
    purpose     = "Basic Peering"
    environment = "Development"
  }

  requester = {
    vpc_id          = var.requester_vpc_id
    route_table_ids = { main = var.requester_route_table_id }
  }

  accepter = {
    vpc_id          = var.accepter_vpc_id
    route_table_ids = { main = var.accepter_route_table_id }
  }
}

output "vpc_peering_connection_id" {
  description = "ID of the peering connection"
  value       = module.vpc_peering.metadata.vpc_peering_connection.id
}
