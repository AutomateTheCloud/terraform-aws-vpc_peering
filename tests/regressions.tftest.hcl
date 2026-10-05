# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
}

# A VPC with no tags at all.
mock_provider "aws" {
  alias = "untagged"
  mock_data "aws_region" {
    defaults = { region = "us-west-2", description = "US West (Oregon)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "222222222222" }
  }
  mock_data "aws_vpc" {
    defaults = { cidr_block = "10.1.0.0/16", tags = {} }
  }
}

variables {
  details   = { scope = "Test", purpose = "Regressions", environment = "test" }
  requester = { vpc_id = "vpc-0123456789abcdef0" }
  accepter  = { vpc_id = "vpc-0fedcba9876543210" }
}

# Regression: a Region missing from the old hard-coded table failed every plan.
run "region_missing_from_old_table" {
  command   = plan
  providers = { aws = aws, aws.peer = aws }
  variables {
    region   = "mx-central-1"
    accepter = { vpc_id = "vpc-0fedcba9876543210", region = "ap-southeast-5" }
  }
  assert {
    condition     = output.metadata.aws.region.abbr == "mxc1" && output.metadata.aws_peer.region.abbr == "apse5"
    error_message = "Expected computed abbreviations for Regions the old table did not list."
  }
}

run "region_abbreviation_override" {
  command   = plan
  providers = { aws = aws, aws.peer = aws }
  variables {
    region   = "us-gov-west-1"
    accepter = { vpc_id = "vpc-0fedcba9876543210", region = "us-gov-east-1" }
  }
  assert {
    condition     = output.metadata.aws.region.abbr == "ugw1" && output.metadata.aws_peer.region.abbr == "uge1"
    error_message = "Expected the override abbreviations for GovCloud."
  }
}

# Regression: a VPC without a Name tag failed every plan.
run "vpc_without_name_tag" {
  command   = plan
  providers = { aws = aws, aws.peer = aws.untagged }
  assert {
    condition     = aws_vpc_peering_connection.this.tags["Name"] == "vpc-0123456789abcdef0 -> vpc-0fedcba9876543210"
    error_message = "A VPC without a Name tag must be named by its ID."
  }
}

# Regression: remote DNS resolution was always turned on, on both sides.
run "remote_dns_resolution_off_by_default" {
  command   = plan
  providers = { aws = aws, aws.peer = aws }
  assert {
    condition     = one(aws_vpc_peering_connection_options.requester.requester).allow_remote_vpc_dns_resolution == false && one(aws_vpc_peering_connection_options.accepter.accepter).allow_remote_vpc_dns_resolution == false
    error_message = "Remote DNS resolution must be off unless asked for."
  }
}

# Regression: two subnets that share a route table gave two identical routes, which
# AWS rejects. Route tables are now listed directly, and each only once.
run "route_table_listed_twice" {
  command   = plan
  providers = { aws = aws, aws.peer = aws }
  variables {
    requester = {
      vpc_id          = "vpc-0123456789abcdef0"
      route_table_ids = { a = "rtb-0123456789abcdef0", b = "rtb-0123456789abcdef0" }
    }
  }
  expect_failures = [var.requester]
}
