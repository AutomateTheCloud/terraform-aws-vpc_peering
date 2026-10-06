# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

##-----------------------------------------------------------------------------
# Data
data "aws_region" "this" {
  region = var.region
}

data "aws_caller_identity" "this" {}

# The accepter side, through the aws.peer provider. Its Region is accepter.region, or
# the aws.peer provider's Region.
data "aws_region" "peer" {
  provider = aws.peer
  region   = var.accepter.region
}

data "aws_caller_identity" "peer" {
  provider = aws.peer
}

# The two VPCs, for their CIDR blocks and Name tags.
data "aws_vpc" "requester" {
  region = var.region
  id     = var.requester.vpc_id
}

data "aws_vpc" "accepter" {
  provider = aws.peer
  region   = var.accepter.region
  id       = var.accepter.vpc_id
}

##-----------------------------------------------------------------------------
# Locals
locals {
  # An abbreviation override counts only when it is set and not empty.
  has_abbr = {
    scope       = var.details.scope_abbr != null && var.details.scope_abbr != ""
    purpose     = var.details.purpose_abbr != null && var.details.purpose_abbr != ""
    environment = var.details.environment_abbr != null && var.details.environment_abbr != ""
  }

  scope = {
    name    = var.details.scope
    abbr    = local.has_abbr.scope ? var.details.scope_abbr : lower(replace(replace(var.details.scope, "/[^0-9A-Za-z]/", " "), "/\\s{1,}/", "_"))
    machine = local.has_abbr.scope ? replace(var.details.scope_abbr, "/[^0-9A-Za-z]/", "") : lower(replace(var.details.scope, "/[^0-9A-Za-z]/", ""))
  }

  purpose = {
    name    = var.details.purpose
    abbr    = local.has_abbr.purpose ? var.details.purpose_abbr : lower(replace(replace(var.details.purpose, "/[^0-9A-Za-z]/", " "), "/\\s{1,}/", "_"))
    machine = local.has_abbr.purpose ? replace(var.details.purpose_abbr, "/[^0-9A-Za-z]/", "") : lower(replace(var.details.purpose, "/[^0-9A-Za-z]/", ""))
  }

  environment = {
    name    = var.details.environment
    abbr    = local.has_abbr.environment ? var.details.environment_abbr : lower(replace(replace(var.details.environment, "/[^0-9A-Za-z]/", " "), "/\\s{1,}/", "_"))
    machine = local.has_abbr.environment ? replace(var.details.environment_abbr, "/[^0-9A-Za-z]/", "") : lower(replace(var.details.environment, "/[^0-9A-Za-z]/", ""))
  }

  tags = merge(
    {
      "Scope"       = local.scope.name,
      "Purpose"     = local.purpose.name,
      "Environment" = local.environment.name,
    },
    var.details.additional_tags
  )

  aws = {
    account = {
      id = data.aws_caller_identity.this.account_id
    }
    region = {
      name        = data.aws_region.this.region
      abbr        = lookup(local.region_abbr_override, data.aws_region.this.region, local.region_abbr_computed)
      description = data.aws_region.this.description
    }
  }

  # Region abbreviation: the geography, the initials of the direction, then the number.
  # us-east-1 => use1, ap-southeast-2 => apse2, eu-central-1 => euc1. Regions that do not
  # follow that pattern are listed in region_abbr_override, so a new Region never fails a plan.
  region_parts = split("-", data.aws_region.this.region)
  region_direction_abbr = {
    north     = "n"
    northeast = "ne"
    northwest = "nw"
    south     = "s"
    southeast = "se"
    southwest = "sw"
    east      = "e"
    west      = "w"
    central   = "c"
  }
  region_abbr_computed = join("", concat(
    [local.region_parts[0]],
    [for p in slice(local.region_parts, 1, length(local.region_parts) - 1) : lookup(local.region_direction_abbr, p, substr(p, 0, 1))],
    [local.region_parts[length(local.region_parts) - 1]]
  ))
  region_abbr_override = {
    us-gov-east-1 = "uge1"
    us-gov-west-1 = "ugw1"
  }
}

##-----------------------------------------------------------------------------
# Locals for the accepter side
locals {
  # The accepter's account and Region, in the same form as local.aws. The Region
  # abbreviation is worked out the same way as the requester's.
  aws_peer = {
    account = {
      id = data.aws_caller_identity.peer.account_id
    }
    region = {
      name        = data.aws_region.peer.region
      abbr        = lookup(local.region_abbr_override, data.aws_region.peer.region, local.peer_region_abbr_computed)
      description = data.aws_region.peer.description
    }
  }

  peer_region_parts = split("-", data.aws_region.peer.region)
  peer_region_abbr_computed = join("", concat(
    [local.peer_region_parts[0]],
    [for p in slice(local.peer_region_parts, 1, length(local.peer_region_parts) - 1) : lookup(local.region_direction_abbr, p, substr(p, 0, 1))],
    [local.peer_region_parts[length(local.peer_region_parts) - 1]]
  ))

  # The Name tag of the peering connection: var.name, or "<requester> -> <accepter>", each
  # VPC by its Name tag, or by its ID when it has none.
  name = coalesce(var.name, format("%s -> %s",
    try(data.aws_vpc.requester.tags["Name"], data.aws_vpc.requester.id),
    try(data.aws_vpc.accepter.tags["Name"], data.aws_vpc.accepter.id),
  ))
}
