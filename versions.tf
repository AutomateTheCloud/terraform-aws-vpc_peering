# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
      # The accepter VPC can be in another AWS account, and only that account can
      # accept the peering connection, so the accepter side uses its own provider
      # configuration. Pass `aws.peer = aws` when both VPCs are in the same account.
      configuration_aliases = [aws.peer]
    }
  }
}
