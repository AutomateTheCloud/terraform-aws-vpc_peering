# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A VPC in one AWS account peered with a VPC in another, in another Region. This is
# common when one account holds shared services, such as a directory or a build system,
# that other accounts reach.

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# The account and Region of the requester VPC.
provider "aws" {
  region = "us-east-1"
}

# The account and Region of the accepter VPC, reached by assuming a role in it.
provider "aws" {
  alias  = "peer"
  region = "us-west-2"

  assume_role {
    role_arn = var.peer_role_arn
  }
}

variable "peer_role_arn" {
  description = "ARN of an IAM role in the accepter account that this configuration can assume, and that may accept the peering connection and add routes"
  type        = string
}

variable "requester_vpc_id" {
  description = "ID of the VPC, in this account and us-east-1, that requests the peering connection"
  type        = string
}

variable "requester_route_table_id" {
  description = "ID of a route table in the requester VPC that gets a route to the accepter VPC"
  type        = string
}

variable "accepter_vpc_id" {
  description = "ID of the VPC, in the accepter account and us-west-2, that accepts the peering connection. Its CIDR block must not overlap the requester VPC's."
  type        = string
}

variable "accepter_route_table_id" {
  description = "ID of a route table in the accepter VPC that gets a route to the requester VPC"
  type        = string
}

module "vpc_peering" {
  source = "../../"

  # The request and the requester's route use the default provider; the acceptance and
  # the accepter's route use aws.peer.
  providers = { aws = aws, aws.peer = aws.peer }

  details = {
    scope       = "Example"
    purpose     = "Cross Account Peering"
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
