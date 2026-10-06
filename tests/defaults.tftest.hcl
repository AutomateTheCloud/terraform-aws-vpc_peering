# Copyright 2026 Automate the Cloud Inc.
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
  details   = { scope = "Test", purpose = "Defaults", environment = "test" }
  requester = { vpc_id = "vpc-0123456789abcdef0" }
  accepter  = { vpc_id = "vpc-0fedcba9876543210" }
}

# Only the required inputs, with both VPCs in one account: the same provider twice.
run "defaults_one_account" {
  command   = plan
  providers = { aws = aws, aws.peer = aws }

  assert {
    condition     = aws_vpc_peering_connection.this.vpc_id == "vpc-0123456789abcdef0" && aws_vpc_peering_connection.this.peer_vpc_id == "vpc-0fedcba9876543210"
    error_message = "The connection must join the requester VPC to the accepter VPC."
  }
  assert {
    condition     = aws_vpc_peering_connection.this.peer_owner_id == "111111111111" && aws_vpc_peering_connection.this.peer_region == "us-east-1"
    error_message = "peer_owner_id and peer_region must be set from the aws.peer provider, here the same account and Region."
  }
  assert {
    condition     = aws_vpc_peering_connection.this.auto_accept == null && aws_vpc_peering_connection_accepter.this.auto_accept == true
    error_message = "The accepter resource, not the request, must accept the connection."
  }
  assert {
    condition     = one(aws_vpc_peering_connection_options.requester.requester).allow_remote_vpc_dns_resolution == false && one(aws_vpc_peering_connection_options.accepter.accepter).allow_remote_vpc_dns_resolution == false
    error_message = "Remote DNS resolution must be off by default on both sides."
  }
  assert {
    condition     = length(aws_route.requester) == 0 && length(aws_route.accepter) == 0
    error_message = "No routes without route_table_ids."
  }
  assert {
    condition = aws_vpc_peering_connection.this.tags == tomap({
      Scope = "Test", Purpose = "Defaults", Environment = "test", Name = "requester -> requester"
    }) && aws_vpc_peering_connection_accepter.this.tags == aws_vpc_peering_connection.this.tags
    error_message = "Unexpected tags."
  }
  assert {
    condition     = output.metadata.aws.account.id == "111111111111" && output.metadata.aws_peer.account.id == "111111111111"
    error_message = "metadata must report both accounts."
  }
}

# The accepter VPC in another account and Region.
run "defaults_two_accounts" {
  command   = plan
  providers = { aws = aws, aws.peer = aws.peer }

  assert {
    condition     = aws_vpc_peering_connection.this.peer_owner_id == "222222222222" && aws_vpc_peering_connection.this.peer_region == "us-west-2"
    error_message = "peer_owner_id and peer_region must come from the aws.peer provider."
  }
  assert {
    condition     = aws_vpc_peering_connection.this.tags["Name"] == "requester -> accepter"
    error_message = "The default name must use each VPC's Name tag."
  }
  assert {
    condition = (
      output.metadata.aws.region.name == "us-east-1" && output.metadata.aws.region.abbr == "use1" &&
      output.metadata.aws_peer.region.name == "us-west-2" && output.metadata.aws_peer.region.abbr == "usw2" &&
      output.metadata.aws_peer.account.id == "222222222222"
    )
    error_message = "metadata must report each side's account and Region."
  }
}

run "details_abbreviations" {
  command   = plan
  providers = { aws = aws, aws.peer = aws }
  variables {
    details = {
      scope            = "Automate the Cloud"
      purpose          = "Shared Services"
      environment      = "Production"
      environment_abbr = "prd"
      additional_tags  = { CostCenter = "1234" }
    }
  }
  assert {
    condition = (
      output.metadata.details.scope.abbr == "automate_the_cloud" &&
      output.metadata.details.scope.machine == "automatethecloud" &&
      output.metadata.details.purpose.abbr == "shared_services" &&
      output.metadata.details.environment.abbr == "prd" &&
      aws_vpc_peering_connection.this.tags["CostCenter"] == "1234"
    )
    error_message = "Unexpected details abbreviations or tags."
  }
}
