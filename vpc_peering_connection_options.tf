# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Each side's options can be changed only by that side's account, once the connection
# is active, so each side has its own resource, created after the acceptance.
resource "aws_vpc_peering_connection_options" "requester" {
  region = var.region

  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.this.id

  requester {
    allow_remote_vpc_dns_resolution = var.requester.allow_remote_vpc_dns_resolution
  }
}

resource "aws_vpc_peering_connection_options" "accepter" {
  provider = aws.peer
  region   = var.accepter.region

  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.this.id

  accepter {
    allow_remote_vpc_dns_resolution = var.accepter.allow_remote_vpc_dns_resolution
  }
}
