# AWS - VPC Peering - Terraform Module
Terraform module to create a VPC Peering Connection (AutomateTheCloud model)

## What's Included?
- [VPC Peering Connection](#vpc-peering-connection)

***

## Usage
```hcl
module "vpc_peering" {
  source    = "../"
  providers = {
    aws.source = aws.source
    aws.peer   = aws.peer
  }

  details = {
    scope               = "Infrastructure"
    purpose             = "VPC Peering"
    environment         = "prd"
    additional_tags = {
      "Project"         = "Project Name"
      "ProjectID"       = "123456789"
      "Contact"         = "David Singer - david.singer@example.com"
    }
  }
  
  vpc_source_id          = "vpc-a234567891234567a"
  subnet_ids_source      = [ "subnet-a1234567891234567", "subnet-b1234567891234567", "subnet-c1234567891234567" ]

  vpc_peer_id            = "vpc-b234567891234567b"
  subnet_ids_peer        = [ "subnet-d1234567891234567", "subnet-e1234567891234567", "subnet-f1234567891234567" ]
}
```

***

## Inputs
| Name | Description | Type | Default |
|------|-------------|:----:|:-------:|
| `subnet_ids_peer` | Subnet IDs (Peer) | `list` | `[]` |
| `subnet_ids_source` | Subnet IDs (Source) | `list` | `[]` |
| `vpc_peer_id` | VPC (Peer): ID | `string` | |
| `vpc_source_id` | VPC (Source): ID | `string` | |

## Inputs (Details)
| Name | Description | Type | Default |
|------|-------------|:----:|:-------:|
| `details.scope` | (Required) Scope Name - What does this object belong to? (Organization Name, Project, etc) | `string` | |
| `details.scope_abbr` | (Optional) Scope [Abbreviation](#Abbreviations) Override | `string` | |
| `details.purpose` | (Required) Purpose Name - What is the purpose or function of this object, or what does this object server? | `string` | |
| `details.purpose_abbr` | (Optional) Purpose [Abbreviation](#Abbreviations) Override | `string` | |
| `details.environment` | (Required) Environment Name | `string` | |
| `details.environment_abbr` | (Optional) Environment [Abbreviation](#Abbreviations) Override | `string` | |
| `details.additional_tags` | (Optional) [Additional Tags](#Additional-Tags) for resources | `map` | `[]` |

***

## Outputs
All outputs from this module are mapped to a single output named `metadata` to make it easier to capture all of the relevant metadata that would be useful when referenced by other stacks (requires only a single output reference in your code, instead of dozens!)

| Name | Description |
|:-----|:------------|
| `details.scope.name` | Scope name |
| `details.scope.abbr` | Scope abbreviation |
| `details.scope.machine` | Scope machine-friendly abbreviation |
| `details.purpose.name` | Purpose name |
| `details.purpose.abbr` | Purpose abbreviation |
| `details.purpose.machine` | Purpose machine-friendly abbreviation |
| `details.environment.name` | Environment name |
| `details.environment.abbr` | Environment abbreviation |
| `details.environment.machine` | Environment machine-friendly abbreviation |
| `details.tags` | Map of tags applied to all resources |
| `source.aws.account.id` | (Source) AWS Account ID |
| `source.aws.region.name` | (Source) AWS Region name, example: `us-east-1` |
| `source.aws.region.abbr` | (Source) AWS Region four letter abbreviation, example: `use1` |
| `source.aws.region.description` | (Source) AWS Region description, example: `US East (N. Virginia)` |
| `source.route_tables` | (Source) Route Tables updated |
| `source.subnets` | (Source) Subnets updated |
| `source.vpc.id` | (Source) (Source) VPC ID |
| `peer.aws.account.id` | (Peer) AWS Account ID |
| `peer.aws.region.name` | (Peer) AWS Region name, example: `us-east-1` |
| `peer.aws.region.abbr` | (Peer) AWS Region four letter abbreviation, example: `use1` |
| `peer.aws.region.description` | (Peer) AWS Region description, example: `US East (N. Virginia)` |
| `peer.route_tables` | (Peer) Route Tables updated |
| `peer.subnets` | (Peer) Subnets updated |
| `peer.vpc.id` | (Peer) (Peer) VPC ID |
| `vpc_peering_connection.id` | VPC Peering Connection ID |

***

## Notes

### Abbreviations
* When generating resource names, the module converts each identifier to a more 'machine-friendly' abbreviated format, removing all special characters, replacing spaces with underscores (_), and converting to lowercase. Example: 'Demo - Module' => 'demo_module'
* Not all resource names allow underscores. When those are encountered, the detail identifier will have the underscore removed (test_example => testexample) automatically. This machine-friendly abbreviation is referred to as 'machine' within the module.
* The abbreviations can be overridden by suppling the abbreviated names (ie: scope_abbr). This is useful when you have a long name and need the created resource names to be shorter. Some resources in AWS have shorter name constraints than others, or you may just prefer it shorter. NOTE: If specifying the Abbreviation, be sure to follow the convention of no spaces and no special characters (except for underscore), otherwise resoure creation may fail.

### Additional Tags
* You can specify additional tags for resources by adding to the `details.additional_tags` map.
```
additional_tags = {
  "Example"         = "Extra Tag"
  "Project"         = "Project Name"
  "CostCenter"      = "123456"
}
```

***

## Terraform Versions
Terraform ~> 1.11.0 is supported.

## Provider Versions
| Name | Version |
|------|---------|
| aws | `~> 5.93` |
