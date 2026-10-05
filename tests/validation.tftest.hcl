# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_vpc" {
    defaults = { cidr_block = "10.0.0.0/16" }
  }
}

variables {
  details   = { scope = "Test", purpose = "Validation", environment = "test" }
  requester = { vpc_id = "vpc-0123456789abcdef0" }
  accepter  = { vpc_id = "vpc-0fedcba9876543210" }
}

run "scope_required" {
  command   = plan
  providers = { aws = aws, aws.peer = aws }
  variables { details = { scope = " ", purpose = "p", environment = "e" } }
  expect_failures = [var.details]
}

run "purpose_required" {
  command   = plan
  providers = { aws = aws, aws.peer = aws }
  variables { details = { scope = "s", purpose = "", environment = "e" } }
  expect_failures = [var.details]
}

run "environment_required" {
  command   = plan
  providers = { aws = aws, aws.peer = aws }
  variables { details = { scope = "s", purpose = "p", environment = "" } }
  expect_failures = [var.details]
}

run "requester_vpc_id_invalid" {
  command   = plan
  providers = { aws = aws, aws.peer = aws }
  variables { requester = { vpc_id = "" } }
  expect_failures = [var.requester]
}

run "accepter_vpc_id_invalid" {
  command   = plan
  providers = { aws = aws, aws.peer = aws }
  variables { accepter = { vpc_id = "subnet-0123456789abcdef0" } }
  expect_failures = [var.accepter]
}

run "short_vpc_ids_accepted" {
  command   = plan
  providers = { aws = aws, aws.peer = aws }
  variables {
    requester = { vpc_id = "vpc-01234567", route_table_ids = { main = "rtb-01234567" } }
    accepter  = { vpc_id = "vpc-89abcdef" }
  }
}

run "same_vpc_twice" {
  command   = plan
  providers = { aws = aws, aws.peer = aws }
  variables { accepter = { vpc_id = "vpc-0123456789abcdef0" } }
  expect_failures = [var.accepter]
}

run "accepter_region_invalid" {
  command   = plan
  providers = { aws = aws, aws.peer = aws }
  variables { accepter = { vpc_id = "vpc-0fedcba9876543210", region = "US West" } }
  expect_failures = [var.accepter]
}

run "requester_route_table_id_invalid" {
  command   = plan
  providers = { aws = aws, aws.peer = aws }
  variables { requester = { vpc_id = "vpc-0123456789abcdef0", route_table_ids = { private = "subnet-0123456789abcdef0" } } }
  expect_failures = [var.requester]
}

run "accepter_route_table_id_invalid" {
  command   = plan
  providers = { aws = aws, aws.peer = aws }
  variables { accepter = { vpc_id = "vpc-0fedcba9876543210", route_table_ids = { private = "rtb-xyz" } } }
  expect_failures = [var.accepter]
}

run "accepter_route_table_listed_twice" {
  command   = plan
  providers = { aws = aws, aws.peer = aws }
  variables {
    accepter = {
      vpc_id          = "vpc-0fedcba9876543210"
      route_table_ids = { a = "rtb-0fedcba9876543210", b = "rtb-0fedcba9876543210" }
    }
  }
  expect_failures = [var.accepter]
}

run "name_empty" {
  command   = plan
  providers = { aws = aws, aws.peer = aws }
  variables { name = " " }
  expect_failures = [var.name]
}
