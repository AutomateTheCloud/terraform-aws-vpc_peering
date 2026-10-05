# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Two VPCs and their route tables, created in the same run as the peering connection,
# so their IDs and CIDR blocks are unknown when the module is planned.
terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 6.0"
      configuration_aliases = [aws.peer]
    }
  }
}

resource "aws_vpc" "requester" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_route_table" "requester" {
  vpc_id = aws_vpc.requester.id
}

resource "aws_vpc" "accepter" {
  provider   = aws.peer
  cidr_block = "10.1.0.0/16"
}

resource "aws_route_table" "accepter" {
  provider = aws.peer
  vpc_id   = aws_vpc.accepter.id
}

module "vpc_peering" {
  source    = "../../.."
  providers = { aws = aws, aws.peer = aws.peer }

  details = { scope = "Test", purpose = "Same Run", environment = "test" }
  requester = {
    vpc_id          = aws_vpc.requester.id
    route_table_ids = { private = aws_route_table.requester.id }
  }
  accepter = {
    vpc_id          = aws_vpc.accepter.id
    route_table_ids = { private = aws_route_table.accepter.id }
  }
}

output "metadata" {
  value = module.vpc_peering.metadata
}
