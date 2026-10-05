# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A route to the other VPC's primary IPv4 CIDR block in each route table listed. The
# routes refer to the accepter resource, so they are created once the connection is
# active. for_each uses the map keys, which come from the inputs, so a route table
# created in the same run still plans.
resource "aws_route" "requester" {
  for_each = var.requester.route_table_ids
  region   = var.region

  route_table_id            = each.value
  destination_cidr_block    = data.aws_vpc.accepter.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.this.id
}

resource "aws_route" "accepter" {
  provider = aws.peer
  for_each = var.accepter.route_table_ids
  region   = var.accepter.region

  route_table_id            = each.value
  destination_cidr_block    = data.aws_vpc.requester.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.this.id
}
