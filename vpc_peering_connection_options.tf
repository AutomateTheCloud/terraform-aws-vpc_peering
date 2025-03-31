resource "aws_vpc_peering_connection_options" "source" {
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.this.id
  requester {
    allow_remote_vpc_dns_resolution = true
  }
  provider = aws.source
}

resource "aws_vpc_peering_connection_options" "peer" {
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.this.id
  accepter {
    allow_remote_vpc_dns_resolution = true
  }
  provider = aws.peer
}
