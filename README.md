# Terraform module for Amazon VPC peering

Creates a VPC peering connection between two VPCs, accepts it, and adds routes to the other VPC in the route tables you list, so that instances in each VPC can reach the other over private IP addresses. The two VPCs can be in the same AWS account and Region, in different Regions, in different accounts, or both.

A connection created with only the required inputs joins the two VPCs but carries no traffic: it adds no routes until you list route tables, and leaves remote DNS resolution off. Security groups and network ACLs in each VPC still decide what traffic is allowed.

## What it configures

| Setting | Default | Input |
|---|---|---|
| Requester VPC | Required | `requester.vpc_id` |
| Accepter VPC | Required | `accepter.vpc_id` |
| Requester account and Region | The default `aws` provider's | `providers`, `region` |
| Accepter account and Region | The `aws.peer` provider's | `providers`, `accepter.region` |
| Accepting the connection | Automatic, with the accepter's provider | |
| Routes to the other VPC | None | `requester.route_table_ids`, `accepter.route_table_ids` |
| Remote DNS resolution | Off on both sides | `requester.allow_remote_vpc_dns_resolution`, `accepter.allow_remote_vpc_dns_resolution` |
| `Name` tag | `<requester VPC name> -> <accepter VPC name>` | `name` |

## Usage

```hcl
module "vpc_peering" {
  source  = "AutomateTheCloud/vpc_peering/aws"
  version = "~> 1.0"

  providers = { aws = aws, aws.peer = aws }

  details = {
    scope       = "Automate the Cloud"
    purpose     = "Shared Services"
    environment = "Production"
  }

  requester = {
    vpc_id          = "vpc-0123456789abcdef0"
    route_table_ids = { private-a = "rtb-0123456789abcdef0", private-b = "rtb-0123456789abcdef1" }
  }

  accepter = {
    vpc_id          = "vpc-0fedcba9876543210"
    route_table_ids = { private = "rtb-0fedcba9876543210" }
  }
}
```

`details`, `requester.vpc_id` and `accepter.vpc_id` are the only required inputs. `details` sets the `Scope`, `Purpose` and `Environment` tags on the peering connection. Each route table listed gets one route, to the other VPC's primary IPv4 CIDR block, through the connection. The names in `route_table_ids`, such as `private-a`, are yours to choose; they only identify each route.

### Providers

The module takes two provider configurations, and every call must pass both:

- `aws` is the requester VPC's account. It requests the peering connection, and adds the requester's routes.
- `aws.peer` is the accepter VPC's account. It accepts the connection, and adds the accepter's routes. Only the accepter's account can accept a peering connection, which is why the module needs a provider for it.

When both VPCs are in the same account, pass the same provider twice: `providers = { aws = aws, aws.peer = aws }`. When the accepter VPC is in another account, pass a provider for that account as `aws.peer`. The [cross-account example](https://github.com/AutomateTheCloud/terraform-aws-vpc_peering/tree/main/examples/cross-account) shows how.

Each side works in its provider's Region. To use another Region without configuring another provider, set `region` for the requester and `accepter.region` for the accepter. Here both VPCs are in one account, in two Regions:

```hcl
module "vpc_peering_cross_region" {
  source  = "AutomateTheCloud/vpc_peering/aws"
  version = "~> 1.0"

  providers = { aws = aws, aws.peer = aws }

  region  = "us-east-1"
  details = { scope = "Automate the Cloud", purpose = "Shared Services", environment = "Production" }

  requester = { vpc_id = "vpc-0123456789abcdef0" }
  accepter  = { vpc_id = "vpc-0fedcba9876543210", region = "us-west-2" }
}
```

## The `details` input

Most modules ask only for what the resource itself needs. This one also requires `details`: three names that say what the peering connection belongs to, what it is for, and which environment it is in. Every Automate the Cloud module takes the same input, and requiring it is deliberate.

```hcl
details = {
  scope       = "Automate the Cloud" # what it belongs to: an organization, team or project
  purpose     = "Web Site"           # what it is for
  environment = "Production"         # which environment
}
```

**Every resource can be traced.** The three names become the `Scope`, `Purpose` and `Environment` tags on every resource the module creates. Months later, anyone looking at a peering connection in the AWS console, or at a line on the bill, can see who it belongs to and why it exists. With cost allocation tags turned on in AWS Billing, the same tags split your bill by project and environment. Because the input is required and checked, no resource can be created without them.

**One definition for a whole stack.** Write `details` once and pass the same value to every module, so the VPCs, the peering connection between them and everything else are tagged alike. Tags you want everywhere, such as a cost center or the Terraform workspace, go in `additional_tags`:

```hcl
locals {
  details = {
    scope           = "Automate the Cloud"
    purpose         = "Web Site"
    environment     = "Production"
    additional_tags = { CostCenter = "1234", IaC = "true" }
  }
}

module "shared_services_peering" {
  source  = "AutomateTheCloud/vpc_peering/aws"
  version = "~> 1.0"

  providers = { aws = aws, aws.peer = aws }

  details   = local.details
  requester = { vpc_id = "vpc-0123456789abcdef0" }
  accepter  = { vpc_id = "vpc-0fedcba9876543210" }
}
```

**Consistent names.** The module turns each name into two short forms other resources can be named with: `abbr`, lowercase with words joined by underscores (`Web Site` becomes `web_site`), and `machine`, lowercase letters and numbers only (`website`), for resources that allow no underscores. It also works out a short form of the Region, such as `use1` for `us-east-1`. Every module derives these the same way, so names stay consistent across a stack. To choose your own short forms, set `scope_abbr`, `purpose_abbr` or `environment_abbr`, for example `environment_abbr = "prd"`.

**One output to reach everything.** All of it comes back in the `metadata` output, along with everything the module created, so a configuration needs only one reference: `module.shared_services_peering.metadata.vpc_peering_connection.id` for the connection's ID, or `module.shared_services_peering.metadata.aws.region.abbr` for the Region's short form.

## Examples

Each example is a complete configuration you can run with `terraform init` and `terraform apply`. They peer VPCs you already have, and leave the VPCs and route tables as they were when you destroy them. A peering connection costs nothing by itself; traffic across it is charged as data transfer between Availability Zones or Regions.

- [Basic peering](https://github.com/AutomateTheCloud/terraform-aws-vpc_peering/tree/main/examples/basic): two VPCs in the same account and Region, with a route on each side.
- [Complete](https://github.com/AutomateTheCloud/terraform-aws-vpc_peering/tree/main/examples/complete): two VPCs in the same account and two Regions, with routes in several route tables, remote DNS resolution and a chosen name.
- [Peering across accounts](https://github.com/AutomateTheCloud/terraform-aws-vpc_peering/tree/main/examples/cross-account): two VPCs in different accounts and Regions, with a provider that assumes a role in the accepter account.

## Things to know

### CIDR blocks

The two VPCs' IPv4 CIDR blocks must not overlap; AWS refuses the connection if they do. Each route goes to the other VPC's primary IPv4 CIDR block only. For a secondary IPv4 CIDR block, or an IPv6 block, add an `aws_route` yourself, with the `metadata` output's `vpc_peering_connection.id` as its `vpc_peering_connection_id`.

### Route tables

List each route table once. A route table can hold only one route for a CIDR block, so the apply fails if a listed route table already has a route for the other VPC's CIDR block, from this module or anywhere else. A subnet uses its VPC's main route table unless it is associated with another one; list the main route table to reach such subnets.

Adding or removing an entry in `route_table_ids` adds or removes only that route. Destroying the module deletes the routes it added and nothing else in the route tables.

### What the connection allows

A peering connection is not transitive: it connects the two VPCs and nothing beyond them. Traffic cannot pass through one VPC to reach the other's internet gateway, NAT gateway, VPN connection or peered VPCs. To connect many VPCs, use a transit gateway instead.

The routes make the other VPC reachable; security groups and network ACLs still decide what is allowed. A security group rule can name a security group in the other VPC only when both VPCs are in the same Region.

### Remote DNS resolution

With `allow_remote_vpc_dns_resolution` on for a side, instances in the other VPC that look up the public DNS hostname of an instance on that side get its private IP address, so their traffic stays on the peering connection. It needs DNS support and DNS hostnames turned on in both VPCs (`enable_dns_support` and `enable_dns_hostnames` on `aws_vpc`). It is off by default, so that each side opts in to sharing its instances' private addresses.

### One account

When both VPCs are in the same account, the module's request and acceptance are two Terraform resources for the same peering connection, and both set the same tags, so they never disagree.

### Changing a VPC or a Region

Changing `requester.vpc_id`, `accepter.vpc_id`, `region` or `accepter.region`, or passing a provider for another account, replaces the peering connection and every route through it. Traffic between the VPCs stops until the new connection is accepted and its routes are in place. The plan shows the connection as replaced; check it before applying.

## Contributing

Contributions are welcome, after review. Read [CONTRIBUTING.md](https://github.com/AutomateTheCloud/terraform-aws-vpc_peering/blob/main/CONTRIBUTING.md) before opening a pull request, and report security problems as described in [SECURITY.md](https://github.com/AutomateTheCloud/terraform-aws-vpc_peering/blob/main/SECURITY.md).

## Testing

The tests in `tests/` run offline against mocked AWS providers, so they need no AWS account:

```shell
terraform init
terraform test
```

## Reference

The sections below are generated from the code by [terraform-docs](https://terraform-docs.io). To update them, run `terraform-docs .`.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (>= 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_accepter"></a> [accepter](#input_accepter)

Description: The VPC that accepts the peering connection, reached through the module's `aws.peer` provider. It can be in another AWS account, another Region, or both.

- `vpc_id` - (Required) The ID of the accepter VPC, such as `vpc-0123456789abcdef0`.
- `region` - (Optional) The accepter VPC's Region, such as `us-west-2`. Defaults to the Region of the `aws.peer` provider.
- `route_table_ids` - (Optional) Route tables in the accepter VPC that get a route to the requester VPC's primary IPv4 CIDR block through the peering connection, as a map of names you choose to route table IDs, such as `{ private = "rtb-0123456789abcdef0" }`. The names only identify each route, so a route table created in the same configuration can be used. Defaults to none: without routes, no traffic crosses the connection.
- `allow_remote_vpc_dns_resolution` - (Optional) Let instances in the requester VPC resolve the public DNS hostnames of instances in the accepter VPC to their private IP addresses. Defaults to `false`. The requester VPC must have DNS support turned on for it to work.

Changing `vpc_id` or `region` replaces the peering connection, and traffic between the VPCs stops until the new one is active.

Type:

```hcl
object({
    vpc_id                          = string
    region                          = optional(string)
    route_table_ids                 = optional(map(string), {})
    allow_remote_vpc_dns_resolution = optional(bool, false)
  })
```

#### <a name="input_details"></a> [details](#input_details)

Description: Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-vpc_peering#the-details-input) explains why it is required.

- `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
- `purpose` - (Required) What the resource is for: `Web Site`.
- `environment` - (Required) The environment: `Production`.
- `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
- `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.

Type:

```hcl
object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
```

#### <a name="input_requester"></a> [requester](#input_requester)

Description: The VPC that requests the peering connection, in the account of the module's default `aws` provider and in `region`.

- `vpc_id` - (Required) The ID of the requester VPC, such as `vpc-0123456789abcdef0`.
- `route_table_ids` - (Optional) Route tables in the requester VPC that get a route to the accepter VPC's primary IPv4 CIDR block through the peering connection, as a map of names you choose to route table IDs, such as `{ private = "rtb-0123456789abcdef0" }`. The names only identify each route, so a route table created in the same configuration can be used. Defaults to none: without routes, no traffic crosses the connection.
- `allow_remote_vpc_dns_resolution` - (Optional) Let instances in the accepter VPC resolve the public DNS hostnames of instances in the requester VPC to their private IP addresses. Defaults to `false`. The accepter VPC must have DNS support turned on for it to work.

Changing `vpc_id` replaces the peering connection, and traffic between the VPCs stops until the new one is active.

Type:

```hcl
object({
    vpc_id                          = string
    route_table_ids                 = optional(map(string), {})
    allow_remote_vpc_dns_resolution = optional(bool, false)
  })
```

### Optional Inputs

The following input variables are optional (have default values):

#### <a name="input_name"></a> [name](#input_name)

Description: The `Name` tag of the peering connection, on both sides. Defaults to `<requester> -> <accepter>`, each VPC by its `Name` tag, or by its ID when it has none.

Type: `string`

Default: `null`

#### <a name="input_region"></a> [region](#input_region)

Description: The requester VPC's Region, such as `us-west-2`: the Region the module creates the peering request, the requester's options and the requester's routes in. Defaults to the Region of the default `aws` provider passed to the module.

Type: `string`

Default: `null`

### Outputs

The following outputs are exported:

#### <a name="output_metadata"></a> [metadata](#output_metadata)

Description: Everything the module created, in one object, so that other configurations need only one reference:

- `details` - The scope, purpose and environment, each with its `name`, `abbr` (lowercase, words joined by underscores) and `machine` (lowercase letters and numbers only) forms, and the `tags` applied to every resource.
- `aws` - The `account.id`, and the `region` `name`, `abbr` (such as `use1` for `us-east-1`) and `description`, of the requester VPC.
- `aws_peer` - The same, for the accepter VPC.
- `vpc_peering_connection` - The peering connection as the requester's account sees it, including its `id` (such as `pcx-0123456789abcdef0`), `accept_status`, `vpc_id`, `peer_vpc_id`, `peer_owner_id` and `peer_region`. `accept_status` and the `requester` and `accepter` options are read when the request is made, so after the apply that creates the connection they still show `pending-acceptance` and the options from before, until the next plan or apply refreshes them.
- `vpc_peering_connection_accepter` - The same connection as the accepter's account sees it, including its `id` and `accept_status`. Its options are read before the module sets them, until the next refresh.
- `vpc_peering_connection_options` - The `requester` and `accepter` options, each with its `id` and its side's `allow_remote_vpc_dns_resolution` setting. These are the settings the module applied.
- `route` - The routes through the connection: `requester` and `accepter`, each keyed like that side's `route_table_ids`, with each route's `id`, `route_table_id`, `destination_cidr_block` and `state`. A side with no route tables has an empty map.
<!-- END_TF_DOCS -->

## License

This module is licensed under the [Apache License 2.0](https://github.com/AutomateTheCloud/terraform-aws-vpc_peering/blob/main/LICENSE). See [NOTICE](https://github.com/AutomateTheCloud/terraform-aws-vpc_peering/blob/main/NOTICE) for the copyright notice.

The Automate the Cloud name and logo are not covered by this license.

---

Maintained by [Automate the Cloud](https://automatethe.cloud), a Kentucky 501(c)(3) that teaches cloud infrastructure and helps nonprofits run theirs.
