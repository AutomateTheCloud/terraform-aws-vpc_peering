terraform {
  required_version = "~> 1.11.0"
}

##-----------------------------------------------------------------------------
# Providers
provider "aws" {
  alias  = "source"
  region = "us-east-1"
}

provider "aws" {
  alias  = "peer"
  region = "us-west-2"
}

##-----------------------------------------------------------------------------
# Module: VPC Peering
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

##-----------------------------------------------------------------------------
# Outputs
output "vpc_peering" {
  description = "VPC Peering"
  value = module.vpc_peering.metadata
}
