resource "aws_vpc_peering_connection_accepter" "this" {
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
  auto_accept               = true
  tags = merge(
    local.tags,
    tomap({
      "Name" = "${data.aws_vpc.source.tags["Name"]} -> ${data.aws_vpc.peer.tags["Name"]}"
    })
  )
  provider = aws.peer
}
