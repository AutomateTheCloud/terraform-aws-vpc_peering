# Complete

Peers two existing VPCs in the same AWS account but in different Regions, `us-east-1` and `us-west-2`, with most of the module's inputs:

- Routes to the other VPC in several route tables on each side.
- Remote DNS resolution on both sides, so an instance's public DNS hostname resolves to its private IP address from the other VPC. Both VPCs need DNS support turned on.
- A chosen `Name` tag, and `details` with an abbreviation override and an extra tag.

Both VPCs are in one account, so the configuration has one provider, and passes it to the module twice. The accepter VPC's Region comes from `accepter.region`, so the module needs no second provider for it.

Traffic between Regions is charged as inter-Region data transfer.

## Run it

Write the inputs to a `terraform.tfvars` file:

```hcl
requester_vpc_id          = "vpc-0123456789abcdef0"
requester_route_table_ids = { private-a = "rtb-0123456789abcdef0", private-b = "rtb-0123456789abcdef1" }
accepter_vpc_id           = "vpc-0fedcba9876543210"
accepter_route_table_ids  = { private = "rtb-0fedcba9876543210" }
```

Then:

```shell
terraform init
terraform apply
```

Remove it with `terraform destroy`. That deletes the peering connection and the routes, and leaves the VPCs and route tables as they were.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_accepter_route_table_ids"></a> [accepter_route_table_ids](#input_accepter_route_table_ids)

Description: Route tables in the accepter VPC that get a route to the requester VPC, as a map of names to IDs

Type: `map(string)`

#### <a name="input_accepter_vpc_id"></a> [accepter_vpc_id](#input_accepter_vpc_id)

Description: ID of a VPC in us-west-2 that accepts the peering connection. Its CIDR block must not overlap the requester VPC's.

Type: `string`

#### <a name="input_requester_route_table_ids"></a> [requester_route_table_ids](#input_requester_route_table_ids)

Description: Route tables in the requester VPC that get a route to the accepter VPC, as a map of names to IDs, such as { private-a = "rtb-0123456789abcdef0" }

Type: `map(string)`

#### <a name="input_requester_vpc_id"></a> [requester_vpc_id](#input_requester_vpc_id)

Description: ID of a VPC in us-east-1 that requests the peering connection

Type: `string`

### Outputs

The following outputs are exported:

#### <a name="output_routes"></a> [routes](#output_routes)

Description: The route table and destination of every route the module created, on each side

#### <a name="output_vpc_peering_connection_id"></a> [vpc_peering_connection_id](#output_vpc_peering_connection_id)

Description: ID of the peering connection
<!-- END_TF_DOCS -->
