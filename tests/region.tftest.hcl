# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
  mock_data "aws_vpc" {
    defaults = { cidr_block = "10.0.0.0/16" }
  }
}

variables {
  details = { scope = "Test", purpose = "Region", environment = "test" }
  requester = {
    vpc_id          = "vpc-0123456789abcdef0"
    route_table_ids = { private = "rtb-0123456789abcdef0" }
  }
  accepter = {
    vpc_id          = "vpc-0fedcba9876543210"
    route_table_ids = { private = "rtb-0fedcba9876543210" }
  }
}

run "provider_region_by_default" {
  command   = plan
  providers = { aws = aws, aws.peer = aws }
  assert {
    condition     = output.metadata.aws.region.name == "us-east-1" && output.metadata.aws_peer.region.name == "us-east-1"
    error_message = "Expected the provider's Region on both sides."
  }
}

# One account, two Regions, with no second provider configuration.
run "region_reaches_every_resource" {
  command   = apply
  providers = { aws = aws, aws.peer = aws }
  variables {
    region = "eu-west-1"
    accepter = {
      vpc_id          = "vpc-0fedcba9876543210"
      region          = "ap-southeast-2"
      route_table_ids = { private = "rtb-0fedcba9876543210" }
    }
  }
  assert {
    condition = alltrue([
      data.aws_vpc.requester.region == "eu-west-1",
      aws_vpc_peering_connection.this.region == "eu-west-1",
      aws_vpc_peering_connection_options.requester.region == "eu-west-1",
      aws_route.requester["private"].region == "eu-west-1",
      output.metadata.aws.region.name == "eu-west-1",
    ])
    error_message = "region was not passed through to every requester resource."
  }
  assert {
    condition = alltrue([
      data.aws_vpc.accepter.region == "ap-southeast-2",
      aws_vpc_peering_connection.this.peer_region == "ap-southeast-2",
      aws_vpc_peering_connection_accepter.this.region == "ap-southeast-2",
      aws_vpc_peering_connection_options.accepter.region == "ap-southeast-2",
      aws_route.accepter["private"].region == "ap-southeast-2",
      output.metadata.aws_peer.region.name == "ap-southeast-2",
    ])
    error_message = "accepter.region was not passed through to every accepter resource."
  }
}
