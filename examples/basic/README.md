# Basic peering

Peers two existing VPCs in the same AWS account and Region, and adds a route to the other VPC in one route table on each side. Remote DNS resolution stays off.

Both VPCs are in one account, so the configuration has one provider, and passes it to the module twice: `providers = { aws = aws, aws.peer = aws }`.

The two VPCs' CIDR blocks must not overlap, and neither route table may already have a route for the other VPC's CIDR block.

## Run it

```shell
terraform init
terraform apply \
  -var 'requester_vpc_id=<VPC ID>' -var 'requester_route_table_id=<route table ID>' \
  -var 'accepter_vpc_id=<VPC ID>' -var 'accepter_route_table_id=<route table ID>'
```

Remove it with `terraform destroy` and the same `-var` options. That deletes the peering connection and the two routes, and leaves the VPCs and route tables as they were.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_accepter_route_table_id"></a> [accepter_route_table_id](#input_accepter_route_table_id)

Description: ID of a route table in the accepter VPC that gets a route to the requester VPC

Type: `string`

#### <a name="input_accepter_vpc_id"></a> [accepter_vpc_id](#input_accepter_vpc_id)

Description: ID of the VPC that accepts the peering connection. Its CIDR block must not overlap the requester VPC's.

Type: `string`

#### <a name="input_requester_route_table_id"></a> [requester_route_table_id](#input_requester_route_table_id)

Description: ID of a route table in the requester VPC that gets a route to the accepter VPC

Type: `string`

#### <a name="input_requester_vpc_id"></a> [requester_vpc_id](#input_requester_vpc_id)

Description: ID of the VPC that requests the peering connection, such as vpc-0123456789abcdef0

Type: `string`

### Outputs

The following outputs are exported:

#### <a name="output_vpc_peering_connection_id"></a> [vpc_peering_connection_id](#output_vpc_peering_connection_id)

Description: ID of the peering connection
<!-- END_TF_DOCS -->
