data "aws_route_table" "peer" {
  count     = (length(var.subnet_ids_peer))
  vpc_id    = data.aws_vpc.peer.id
  subnet_id = var.subnet_ids_peer[count.index]
  provider  = aws.peer
}

data "aws_route_table" "source" {
  count     = (length(var.subnet_ids_source))
  vpc_id    = data.aws_vpc.source.id
  subnet_id = var.subnet_ids_source[count.index]
  provider  = aws.source
}

data "aws_vpc" "peer" {
  id       = var.vpc_peer_id
  provider = aws.peer
}

data "aws_vpc" "source" {
  id       = var.vpc_source_id
  provider = aws.source
}
