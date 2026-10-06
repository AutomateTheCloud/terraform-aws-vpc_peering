# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
}
mock_provider "aws" {
  alias = "peer"
  mock_data "aws_region" {
    defaults = { region = "us-west-2", description = "US West (Oregon)" }
  }
}

# Regression: routes were counted from data sources, which cannot be read at plan time
# for VPCs created in the same run. They now follow the keys of route_table_ids.
run "network_created_in_same_run" {
  command   = plan
  providers = { aws = aws, aws.peer = aws.peer }
  module {
    source = "./tests/fixtures/same_run_network"
  }
  assert {
    condition     = length(module.vpc_peering.metadata.route.requester) == 1 && length(module.vpc_peering.metadata.route.accepter) == 1
    error_message = "Routes were not planned."
  }
}
