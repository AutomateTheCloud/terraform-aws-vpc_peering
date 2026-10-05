# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Two existing VPCs in the same AWS account and in two Regions, with most of the
# module's inputs: routes in several route tables on each side, remote DNS resolution
# on both sides, and a chosen name.

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# The requester VPC's Region.
provider "aws" {
  region = "us-east-1"
}

variable "requester_vpc_id" {
  description = "ID of a VPC in us-east-1 that requests the peering connection"
  type        = string
}

variable "requester_route_table_ids" {
  description = "Route tables in the requester VPC that get a route to the accepter VPC, as a map of names to IDs, such as { private-a = \"rtb-0123456789abcdef0\" }"
  type        = map(string)
}

variable "accepter_vpc_id" {
  description = "ID of a VPC in us-west-2 that accepts the peering connection. Its CIDR block must not overlap the requester VPC's."
  type        = string
}

variable "accepter_route_table_ids" {
  description = "Route tables in the accepter VPC that get a route to the requester VPC, as a map of names to IDs"
  type        = map(string)
}

locals {
  details = {
    scope            = "Example"
    purpose          = "Shared Services"
    environment      = "Development"
    environment_abbr = "dev"
    additional_tags  = { CostCenter = "1234" }
  }
}

module "vpc_peering" {
  source = "../../"

  # One account, so the same provider is passed twice. The accepter VPC is in another
  # Region, set with accepter.region, so no second provider is needed.
  providers = { aws = aws, aws.peer = aws }

  details = local.details
  name    = "shared-services-use1-to-usw2"

  requester = {
    vpc_id                          = var.requester_vpc_id
    route_table_ids                 = var.requester_route_table_ids
    allow_remote_vpc_dns_resolution = true
  }

  accepter = {
    vpc_id                          = var.accepter_vpc_id
    region                          = "us-west-2"
    route_table_ids                 = var.accepter_route_table_ids
    allow_remote_vpc_dns_resolution = true
  }
}

output "vpc_peering_connection_id" {
  description = "ID of the peering connection"
  value       = module.vpc_peering.metadata.vpc_peering_connection.id
}

output "routes" {
  description = "The route table and destination of every route the module created, on each side"
  value = {
    for side, routes in module.vpc_peering.metadata.route : side => {
      for name, r in routes : name => "${r.route_table_id} -> ${r.destination_cidr_block}"
    }
  }
}
