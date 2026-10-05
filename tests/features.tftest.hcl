# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Offline tests: every provider is mocked, so no AWS account is used.
# The requester account.
mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
  mock_data "aws_vpc" {
    defaults = { cidr_block = "10.0.0.0/16", tags = { Name = "requester" } }
  }
}

# The accepter account. Its VPCs have a different CIDR block and Name tag, and its
# routes a recognizable origin, so a test can tell which provider was used.
mock_provider "aws" {
  alias = "peer"
  mock_data "aws_region" {
    defaults = { region = "us-west-2", description = "US West (Oregon)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "222222222222" }
  }
  mock_data "aws_vpc" {
    defaults = { cidr_block = "10.1.0.0/16", tags = { Name = "accepter" } }
  }
  mock_resource "aws_route" {
    defaults = { origin = "created-by-aws-peer" }
  }
}


variables {
  details   = { scope = "Test", purpose = "Features", environment = "test" }
  requester = { vpc_id = "vpc-0123456789abcdef0" }
  accepter  = { vpc_id = "vpc-0fedcba9876543210" }
}

run "routes_on_both_sides" {
  command   = apply
  providers = { aws = aws, aws.peer = aws.peer }
  variables {
    requester = {
      vpc_id          = "vpc-0123456789abcdef0"
      route_table_ids = { private-a = "rtb-0123456789abcdef0", private-b = "rtb-0123456789abcdef1" }
    }
    accepter = {
      vpc_id          = "vpc-0fedcba9876543210"
      route_table_ids = { shared = "rtb-0fedcba9876543210" }
    }
  }
  assert {
    condition = (
      aws_route.requester["private-a"].route_table_id == "rtb-0123456789abcdef0" &&
      aws_route.requester["private-b"].route_table_id == "rtb-0123456789abcdef1" &&
      aws_route.requester["private-a"].destination_cidr_block == "10.1.0.0/16" &&
      aws_route.accepter["shared"].route_table_id == "rtb-0fedcba9876543210" &&
      aws_route.accepter["shared"].destination_cidr_block == "10.0.0.0/16"
    )
    error_message = "Each side's routes must go to the other VPC's CIDR block."
  }
  assert {
    condition     = aws_route.accepter["shared"].origin == "created-by-aws-peer" && aws_route.requester["private-a"].origin != "created-by-aws-peer"
    error_message = "Each side's routes must be created with that side's provider."
  }
  assert {
    condition     = aws_route.requester["private-a"].vpc_peering_connection_id == aws_vpc_peering_connection_accepter.this.id
    error_message = "Routes must use the accepted connection."
  }
  assert {
    condition     = keys(output.metadata.route.requester) == ["private-a", "private-b"] && keys(output.metadata.route.accepter) == ["shared"]
    error_message = "metadata.route must be keyed like route_table_ids."
  }
}

run "remote_dns_resolution" {
  command   = plan
  providers = { aws = aws, aws.peer = aws.peer }
  variables {
    requester = { vpc_id = "vpc-0123456789abcdef0", allow_remote_vpc_dns_resolution = true }
    accepter  = { vpc_id = "vpc-0fedcba9876543210" }
  }
  assert {
    condition     = one(aws_vpc_peering_connection_options.requester.requester).allow_remote_vpc_dns_resolution == true && one(aws_vpc_peering_connection_options.accepter.accepter).allow_remote_vpc_dns_resolution == false
    error_message = "Each side's setting must apply only to that side."
  }
}

run "name" {
  command   = plan
  providers = { aws = aws, aws.peer = aws.peer }
  variables { name = "shared-services" }
  assert {
    condition     = aws_vpc_peering_connection.this.tags["Name"] == "shared-services" && aws_vpc_peering_connection_accepter.this.tags["Name"] == "shared-services"
    error_message = "name must set the Name tag on both sides."
  }
}
