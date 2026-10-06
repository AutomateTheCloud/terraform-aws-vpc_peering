# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# The acceptance, made by the accepter VPC's account. When both VPCs are in one account
# and Region, this resource and aws_vpc_peering_connection.this manage the same
# connection, and both set the same tags.
resource "aws_vpc_peering_connection_accepter" "this" {
  provider = aws.peer
  region   = var.accepter.region

  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
  auto_accept               = true

  tags = merge(local.tags, { "Name" = local.name })
}
