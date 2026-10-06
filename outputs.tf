# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

output "metadata" {
  description = <<-EOT
    Everything the module created, in one object, so that other configurations need only one reference:

    - `details` - The scope, purpose and environment, each with its `name`, `abbr` (lowercase, words joined by underscores) and `machine` (lowercase letters and numbers only) forms, and the `tags` applied to every resource.
    - `aws` - The `account.id`, and the `region` `name`, `abbr` (such as `use1` for `us-east-1`) and `description`, of the requester VPC.
    - `aws_peer` - The same, for the accepter VPC.
    - `vpc_peering_connection` - The peering connection as the requester's account sees it, including its `id` (such as `pcx-0123456789abcdef0`), `accept_status`, `vpc_id`, `peer_vpc_id`, `peer_owner_id` and `peer_region`. `accept_status` and the `requester` and `accepter` options are read when the request is made, so after the apply that creates the connection they still show `pending-acceptance` and the options from before, until the next plan or apply refreshes them.
    - `vpc_peering_connection_accepter` - The same connection as the accepter's account sees it, including its `id` and `accept_status`. Its options are read before the module sets them, until the next refresh.
    - `vpc_peering_connection_options` - The `requester` and `accepter` options, each with its `id` and its side's `allow_remote_vpc_dns_resolution` setting. These are the settings the module applied.
    - `route` - The routes through the connection: `requester` and `accepter`, each keyed like that side's `route_table_ids`, with each route's `id`, `route_table_id`, `destination_cidr_block` and `state`. A side with no route tables has an empty map.
  EOT
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

    aws = {
      account = {
        id = local.aws.account.id
      }
      region = {
        name        = local.aws.region.name
        abbr        = local.aws.region.abbr
        description = local.aws.region.description
      }
    }

    aws_peer = {
      account = {
        id = local.aws_peer.account.id
      }
      region = {
        name        = local.aws_peer.region.name
        abbr        = local.aws_peer.region.abbr
        description = local.aws_peer.region.description
      }
    }

    # One entry per resource. Every resource is always created.
    vpc_peering_connection          = local.output_resources.vpc_peering_connection
    vpc_peering_connection_accepter = local.output_resources.vpc_peering_connection_accepter
    vpc_peering_connection_options  = local.output_resources.vpc_peering_connection_options
    route                           = local.output_resources.route
  }
}

# Each resource's attributes, listed one by one: referencing a whole resource would
# also reference its deprecated and sensitive attributes, and every caller's plan
# would then print warnings or the output would become sensitive.
locals {
  output_resources = {
    vpc_peering_connection = {
      accept_status = aws_vpc_peering_connection.this.accept_status
      accepter      = aws_vpc_peering_connection.this.accepter
      auto_accept   = aws_vpc_peering_connection.this.auto_accept
      id            = aws_vpc_peering_connection.this.id
      peer_owner_id = aws_vpc_peering_connection.this.peer_owner_id
      peer_region   = aws_vpc_peering_connection.this.peer_region
      peer_vpc_id   = aws_vpc_peering_connection.this.peer_vpc_id
      region        = aws_vpc_peering_connection.this.region
      requester     = aws_vpc_peering_connection.this.requester
      tags          = aws_vpc_peering_connection.this.tags
      tags_all      = aws_vpc_peering_connection.this.tags_all
      vpc_id        = aws_vpc_peering_connection.this.vpc_id
    }

    vpc_peering_connection_accepter = {
      accept_status             = aws_vpc_peering_connection_accepter.this.accept_status
      accepter                  = aws_vpc_peering_connection_accepter.this.accepter
      auto_accept               = aws_vpc_peering_connection_accepter.this.auto_accept
      id                        = aws_vpc_peering_connection_accepter.this.id
      peer_owner_id             = aws_vpc_peering_connection_accepter.this.peer_owner_id
      peer_region               = aws_vpc_peering_connection_accepter.this.peer_region
      peer_vpc_id               = aws_vpc_peering_connection_accepter.this.peer_vpc_id
      region                    = aws_vpc_peering_connection_accepter.this.region
      requester                 = aws_vpc_peering_connection_accepter.this.requester
      tags                      = aws_vpc_peering_connection_accepter.this.tags
      tags_all                  = aws_vpc_peering_connection_accepter.this.tags_all
      vpc_id                    = aws_vpc_peering_connection_accepter.this.vpc_id
      vpc_peering_connection_id = aws_vpc_peering_connection_accepter.this.vpc_peering_connection_id
    }

    vpc_peering_connection_options = {
      requester = {
        id                        = aws_vpc_peering_connection_options.requester.id
        region                    = aws_vpc_peering_connection_options.requester.region
        requester                 = aws_vpc_peering_connection_options.requester.requester
        vpc_peering_connection_id = aws_vpc_peering_connection_options.requester.vpc_peering_connection_id
      }
      accepter = {
        accepter                  = aws_vpc_peering_connection_options.accepter.accepter
        id                        = aws_vpc_peering_connection_options.accepter.id
        region                    = aws_vpc_peering_connection_options.accepter.region
        vpc_peering_connection_id = aws_vpc_peering_connection_options.accepter.vpc_peering_connection_id
      }
    }

    # Keyed like each side's route_table_ids. Only the attributes a peering route sets;
    # the other targets (gateways, instances, endpoints) are always empty here.
    route = {
      requester = {
        for k in keys(var.requester.route_table_ids) : k => {
          destination_cidr_block    = aws_route.requester[k].destination_cidr_block
          id                        = aws_route.requester[k].id
          origin                    = aws_route.requester[k].origin
          region                    = aws_route.requester[k].region
          route_table_id            = aws_route.requester[k].route_table_id
          state                     = aws_route.requester[k].state
          vpc_peering_connection_id = aws_route.requester[k].vpc_peering_connection_id
        }
      }
      accepter = {
        for k in keys(var.accepter.route_table_ids) : k => {
          destination_cidr_block    = aws_route.accepter[k].destination_cidr_block
          id                        = aws_route.accepter[k].id
          origin                    = aws_route.accepter[k].origin
          region                    = aws_route.accepter[k].region
          route_table_id            = aws_route.accepter[k].route_table_id
          state                     = aws_route.accepter[k].state
          vpc_peering_connection_id = aws_route.accepter[k].vpc_peering_connection_id
        }
      }
    }
  }
}
