resource "aws_route" "peer" {
  count                     = length(var.subnet_ids_peer)
  route_table_id            = data.aws_route_table.peer[count.index].route_table_id
  destination_cidr_block    = data.aws_vpc.source.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
  provider                  = aws.peer
}

resource "aws_route" "source" {
  count                     = length(var.subnet_ids_source)
  route_table_id            = data.aws_route_table.source[count.index].route_table_id
  destination_cidr_block    = data.aws_vpc.peer.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
  provider                  = aws.source
}
