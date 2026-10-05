# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

variable "accepter" {
  description = <<-EOT
    The VPC that accepts the peering connection, reached through the module's `aws.peer` provider. It can be in another AWS account, another Region, or both.

    - `vpc_id` - (Required) The ID of the accepter VPC, such as `vpc-0123456789abcdef0`.
    - `region` - (Optional) The accepter VPC's Region, such as `us-west-2`. Defaults to the Region of the `aws.peer` provider.
    - `route_table_ids` - (Optional) Route tables in the accepter VPC that get a route to the requester VPC's primary IPv4 CIDR block through the peering connection, as a map of names you choose to route table IDs, such as `{ private = "rtb-0123456789abcdef0" }`. The names only identify each route, so a route table created in the same configuration can be used. Defaults to none: without routes, no traffic crosses the connection.
    - `allow_remote_vpc_dns_resolution` - (Optional) Let instances in the requester VPC resolve the public DNS hostnames of instances in the accepter VPC to their private IP addresses. Defaults to `false`. The requester VPC must have DNS support turned on for it to work.

    Changing `vpc_id` or `region` replaces the peering connection, and traffic between the VPCs stops until the new one is active.
  EOT
  type = object({
    vpc_id                          = string
    region                          = optional(string)
    route_table_ids                 = optional(map(string), {})
    allow_remote_vpc_dns_resolution = optional(bool, false)
  })
  nullable = false

  validation {
    condition     = can(regex("^vpc-[0-9a-f]{8}([0-9a-f]{9})?$", var.accepter.vpc_id))
    error_message = "accepter.vpc_id must be a VPC ID, such as vpc-0123456789abcdef0."
  }

  validation {
    condition     = var.accepter.region == null || can(regex("^[a-z]{2}(-[a-z]+)+-[0-9]+$", var.accepter.region))
    error_message = "accepter.region must be a Region name, such as us-west-2."
  }

  validation {
    condition     = alltrue([for id in values(var.accepter.route_table_ids) : can(regex("^rtb-[0-9a-f]{8}([0-9a-f]{9})?$", id))])
    error_message = "Each accepter.route_table_ids value must be a route table ID, such as rtb-0123456789abcdef0."
  }

  validation {
    condition     = length(distinct(values(var.accepter.route_table_ids))) == length(var.accepter.route_table_ids)
    error_message = "accepter.route_table_ids lists a route table more than once. A route table can hold only one route to the requester VPC's CIDR block."
  }

  validation {
    condition     = var.accepter.vpc_id != var.requester.vpc_id
    error_message = "accepter.vpc_id and requester.vpc_id must be different VPCs."
  }
}

variable "details" {
  description = <<-EOT
    Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-vpc_peering#the-details-input) explains why it is required.

    - `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
    - `purpose` - (Required) What the resource is for: `Web Site`.
    - `environment` - (Required) The environment: `Production`.
    - `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
    - `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.
  EOT
  type = object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
  nullable = false

  validation {
    condition     = trimspace(var.details.scope) != ""
    error_message = "Scope not specified."
  }

  validation {
    condition     = trimspace(var.details.purpose) != ""
    error_message = "Purpose not specified."
  }

  validation {
    condition     = trimspace(var.details.environment) != ""
    error_message = "Environment not specified."
  }
}

variable "name" {
  description = <<-EOT
    The `Name` tag of the peering connection, on both sides. Defaults to `<requester> -> <accepter>`, each VPC by its `Name` tag, or by its ID when it has none.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.name == null || try(trimspace(var.name) != "", false)
    error_message = "name must not be empty. Leave it out for the default name."
  }
}

variable "region" {
  description = <<-EOT
    The requester VPC's Region, such as `us-west-2`: the Region the module creates the peering request, the requester's options and the requester's routes in. Defaults to the Region of the default `aws` provider passed to the module.
  EOT
  type        = string
  default     = null
}

variable "requester" {
  description = <<-EOT
    The VPC that requests the peering connection, in the account of the module's default `aws` provider and in `region`.

    - `vpc_id` - (Required) The ID of the requester VPC, such as `vpc-0123456789abcdef0`.
    - `route_table_ids` - (Optional) Route tables in the requester VPC that get a route to the accepter VPC's primary IPv4 CIDR block through the peering connection, as a map of names you choose to route table IDs, such as `{ private = "rtb-0123456789abcdef0" }`. The names only identify each route, so a route table created in the same configuration can be used. Defaults to none: without routes, no traffic crosses the connection.
    - `allow_remote_vpc_dns_resolution` - (Optional) Let instances in the accepter VPC resolve the public DNS hostnames of instances in the requester VPC to their private IP addresses. Defaults to `false`. The accepter VPC must have DNS support turned on for it to work.

    Changing `vpc_id` replaces the peering connection, and traffic between the VPCs stops until the new one is active.
  EOT
  type = object({
    vpc_id                          = string
    route_table_ids                 = optional(map(string), {})
    allow_remote_vpc_dns_resolution = optional(bool, false)
  })
  nullable = false

  validation {
    condition     = can(regex("^vpc-[0-9a-f]{8}([0-9a-f]{9})?$", var.requester.vpc_id))
    error_message = "requester.vpc_id must be a VPC ID, such as vpc-0123456789abcdef0."
  }

  validation {
    condition     = alltrue([for id in values(var.requester.route_table_ids) : can(regex("^rtb-[0-9a-f]{8}([0-9a-f]{9})?$", id))])
    error_message = "Each requester.route_table_ids value must be a route table ID, such as rtb-0123456789abcdef0."
  }

  validation {
    condition     = length(distinct(values(var.requester.route_table_ids))) == length(var.requester.route_table_ids)
    error_message = "requester.route_table_ids lists a route table more than once. A route table can hold only one route to the accepter VPC's CIDR block."
  }
}
