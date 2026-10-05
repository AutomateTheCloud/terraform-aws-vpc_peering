# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# The request, made by the requester VPC's account. peer_owner_id and peer_region are
# always set, so the same code works within one account and Region, across Regions,
# and across accounts.
resource "aws_vpc_peering_connection" "this" {
  region = var.region

  vpc_id        = data.aws_vpc.requester.id
  peer_vpc_id   = data.aws_vpc.accepter.id
  peer_owner_id = data.aws_caller_identity.peer.account_id
  peer_region   = data.aws_region.peer.region

  tags = merge(local.tags, { "Name" = local.name })
}
