# Peering across accounts

Peers a VPC in one AWS account with a VPC in another account and another Region. Many organizations keep shared services in one account and reach them from the others.

The configuration has two providers. The default `aws` provider requests the peering connection and adds the requester's route. The `aws.peer` provider assumes a role in the accepter account, accepts the connection, and adds the accepter's route there. The module receives both through `providers = { aws = aws, aws.peer = aws.peer }`. The accepter's Region is the `aws.peer` provider's, `us-west-2`.

The role in the accepter account must trust the identity that runs Terraform, and allow `ec2:AcceptVpcPeeringConnection`, `ec2:DescribeVpcPeeringConnections`, `ec2:ModifyVpcPeeringConnectionOptions`, `ec2:DescribeVpcs`, `ec2:CreateRoute`, `ec2:DeleteRoute`, `ec2:DescribeRouteTables`, `ec2:CreateTags` and `ec2:DeleteTags`. Limit `ec2:CreateRoute` and `ec2:DeleteRoute` to the route tables you list.

## Run it

```shell
terraform init
terraform apply \
  -var 'peer_role_arn=<role ARN in the accepter account>' \
  -var 'requester_vpc_id=<VPC ID>' -var 'requester_route_table_id=<route table ID>' \
  -var 'accepter_vpc_id=<VPC ID>' -var 'accepter_route_table_id=<route table ID>'
```

Remove it with `terraform destroy` and the same `-var` options.

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

Description: ID of the VPC, in the accepter account and us-west-2, that accepts the peering connection. Its CIDR block must not overlap the requester VPC's.

Type: `string`

#### <a name="input_peer_role_arn"></a> [peer_role_arn](#input_peer_role_arn)

Description: ARN of an IAM role in the accepter account that this configuration can assume, and that may accept the peering connection and add routes

Type: `string`

#### <a name="input_requester_route_table_id"></a> [requester_route_table_id](#input_requester_route_table_id)

Description: ID of a route table in the requester VPC that gets a route to the accepter VPC

Type: `string`

#### <a name="input_requester_vpc_id"></a> [requester_vpc_id](#input_requester_vpc_id)

Description: ID of the VPC, in this account and us-east-1, that requests the peering connection

Type: `string`

### Outputs

The following outputs are exported:

#### <a name="output_vpc_peering_connection_id"></a> [vpc_peering_connection_id](#output_vpc_peering_connection_id)

Description: ID of the peering connection
<!-- END_TF_DOCS -->
