output "metadata" {
  description = "Metadata"
  value = {
    details = {
      scope = {
        name    = local.scope.name
        abbr    = local.scope.abbr
        machine = local.scope.machine
      }
      purpose = {
        name    = local.purpose.name
        abbr    = local.purpose.abbr
        machine = local.purpose.machine
      }
      environment = {
        name    = local.environment.name
        abbr    = local.environment.abbr
        machine = local.environment.machine
      }
      tags = local.tags
    }

    source = {
      aws = {
        account = {
          id = local.aws.source.account.id
        }
        region = {
          name        = local.aws.source.region.name
          abbr        = local.aws.source.region.abbr
          description = local.aws.source.region.description
        }
      }

      route_tables = data.aws_route_table.source[*].route_table_id

      subnets = var.subnet_ids_source

      vpc = {
        id = data.aws_vpc.source.id
      }
    }
    peer = {
      aws = {
        account = {
          id = local.aws.peer.account.id
        }
        region = {
          name        = local.aws.peer.region.name
          abbr        = local.aws.peer.region.abbr
          description = local.aws.peer.region.description
        }
      }

      route_tables = data.aws_route_table.peer[*].route_table_id

      subnets = var.subnet_ids_peer

      vpc = {
        id = data.aws_vpc.peer.id
      }
    }
    vpc_peering_connection = {
      id = aws_vpc_peering_connection.this.id
    }
  }
}
