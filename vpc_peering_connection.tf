resource "aws_vpc_peering_connection" "this" {
  peer_owner_id = data.aws_caller_identity.peer.account_id
  vpc_id        = data.aws_vpc.source.id
  peer_vpc_id   = data.aws_vpc.peer.id
  peer_region   = data.aws_region.peer.name
  tags = merge(
    local.tags,
    tomap({
      "Name" = "${data.aws_vpc.source.tags["Name"]} -> ${data.aws_vpc.peer.tags["Name"]}"
    })
  )
  provider = aws.source
}
