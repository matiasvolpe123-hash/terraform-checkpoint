# Output de terraform plan

- Fecha: 2026-10-11
- Región: us-east-2
- Versión de Terraform: Terraform v1.16.4

```

Warning: Deprecated Parameter

The parameter "dynamodb_table" is deprecated. Use parameter "use_lockfile"
instead.
Acquiring state lock. This may take a few moments...
module.identity.data.aws_iam_policy_document.processing_assume_role: Reading...
module.network.data.aws_region.current: Reading...
module.identity.data.aws_caller_identity.current: Reading...
data.aws_availability_zones.available: Reading...
module.identity.data.aws_iam_policy_document.processing_s3: Reading...
module.identity.data.aws_iam_policy_document.processing_assume_role: Read complete after 0s [id=3384017370]
module.identity.data.aws_iam_policy_document.processing_s3: Read complete after 0s [id=749605304]
module.network.data.aws_region.current: Read complete after 0s [id=us-east-2]
module.identity.data.aws_caller_identity.current: Read complete after 1s [id=683590131550]
module.identity.data.aws_iam_policy_document.audit_assume_role: Reading...
module.identity.data.aws_iam_policy_document.audit_assume_role: Read complete after 0s [id=2512970166]
data.aws_availability_zones.available: Read complete after 2s [id=us-east-2]

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # module.identity.aws_iam_policy.processing_s3 will be created
  + resource "aws_iam_policy" "processing_s3" {
      + arn              = (known after apply)
      + attachment_count = (known after apply)
      + description      = "Permite s3:ListBucket, s3:GetObject y s3:PutObject unicamente sobre el prefijo streaming/raw."
      + id               = (known after apply)
      + name             = "datalake-dev-processing-s3-prefix-access"
      + name_prefix      = (known after apply)
      + path             = "/"
      + policy           = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = "s3:ListBucket"
                      + Condition = {
                          + StringLike = {
                              + "s3:prefix" = [
                                  + "streaming/raw",
                                  + "streaming/raw/*",
                                ]
                            }
                        }
                      + Effect    = "Allow"
                      + Resource  = "arn:aws:s3:::datalake-683590131550-dev"
                      + Sid       = "ListBucketOnlyUnderPrefix"
                    },
                  + {
                      + Action   = [
                          + "s3:PutObject",
                          + "s3:GetObject",
                        ]
                      + Effect   = "Allow"
                      + Resource = "arn:aws:s3:::datalake-683590131550-dev/streaming/raw/*"
                      + Sid      = "ReadWriteObjectsUnderPrefix"
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + policy_id        = (known after apply)
      + tags             = {
          + "ManagedBy" = "terraform"
          + "Module"    = "identity"
        }
      + tags_all         = {
          + "Environment" = "dev"
          + "ManagedBy"   = "terraform"
          + "Module"      = "identity"
          + "Project"     = "data-engineering-checkpoint"
        }
    }

  # module.identity.aws_iam_role.audit will be created
  + resource "aws_iam_role" "audit" {
      + arn                   = (known after apply)
      + assume_role_policy    = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = "sts:AssumeRole"
                      + Effect    = "Allow"
                      + Principal = {
                          + AWS = "arn:aws:iam::683590131550:root"
                        }
                      + Sid       = "AllowAuditorsToAssumeRole"
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + create_date           = (known after apply)
      + description           = "Rol de solo lectura para auditoria del plano de control."
      + force_detach_policies = false
      + id                    = (known after apply)
      + managed_policy_arns   = (known after apply)
      + max_session_duration  = 3600
      + name                  = "datalake-dev-control-plane-audit-role"
      + name_prefix           = (known after apply)
      + path                  = "/"
      + tags                  = {
          + "ManagedBy" = "terraform"
          + "Module"    = "identity"
          + "Name"      = "datalake-dev-control-plane-audit-role"
          + "Plane"     = "control"
        }
      + tags_all              = {
          + "Environment" = "dev"
          + "ManagedBy"   = "terraform"
          + "Module"      = "identity"
          + "Name"        = "datalake-dev-control-plane-audit-role"
          + "Plane"       = "control"
          + "Project"     = "data-engineering-checkpoint"
        }
      + unique_id             = (known after apply)

      + inline_policy (known after apply)
    }

  # module.identity.aws_iam_role.processing will be created
  + resource "aws_iam_role" "processing" {
      + arn                   = (known after apply)
      + assume_role_policy    = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = "sts:AssumeRole"
                      + Effect    = "Allow"
                      + Principal = {
                          + Service = [
                              + "lambda.amazonaws.com",
                              + "kinesisanalytics.amazonaws.com",
                            ]
                        }
                      + Sid       = "AllowServiceToAssumeRole"
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + create_date           = (known after apply)
      + description           = "Rol de ejecución para servicios de procesamiento de datos (Lambda / Flink)."
      + force_detach_policies = false
      + id                    = (known after apply)
      + managed_policy_arns   = (known after apply)
      + max_session_duration  = 3600
      + name                  = "datalake-dev-processing-execution-role"
      + name_prefix           = (known after apply)
      + path                  = "/"
      + tags                  = {
          + "ManagedBy" = "terraform"
          + "Module"    = "identity"
          + "Name"      = "datalake-dev-processing-execution-role"
          + "Plane"     = "data"
        }
      + tags_all              = {
          + "Environment" = "dev"
          + "ManagedBy"   = "terraform"
          + "Module"      = "identity"
          + "Name"        = "datalake-dev-processing-execution-role"
          + "Plane"       = "data"
          + "Project"     = "data-engineering-checkpoint"
        }
      + unique_id             = (known after apply)

      + inline_policy (known after apply)
    }

  # module.identity.aws_iam_role_policy_attachment.audit_security_audit will be created
  + resource "aws_iam_role_policy_attachment" "audit_security_audit" {
      + id         = (known after apply)
      + policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
      + role       = "datalake-dev-control-plane-audit-role"
    }

  # module.identity.aws_iam_role_policy_attachment.processing_s3 will be created
  + resource "aws_iam_role_policy_attachment" "processing_s3" {
      + id         = (known after apply)
      + policy_arn = (known after apply)
      + role       = "datalake-dev-processing-execution-role"
    }

  # module.network.aws_default_security_group.this will be created
  + resource "aws_default_security_group" "this" {
      + arn                    = (known after apply)
      + description            = (known after apply)
      + egress                 = (known after apply)
      + id                     = (known after apply)
      + ingress                = (known after apply)
      + name                   = (known after apply)
      + name_prefix            = (known after apply)
      + owner_id               = (known after apply)
      + revoke_rules_on_delete = false
      + tags                   = {
          + "ManagedBy" = "terraform"
          + "Module"    = "network"
          + "Name"      = "datalake-dev-default-sg-locked"
        }
      + tags_all               = {
          + "Environment" = "dev"
          + "ManagedBy"   = "terraform"
          + "Module"      = "network"
          + "Name"        = "datalake-dev-default-sg-locked"
          + "Project"     = "data-engineering-checkpoint"
        }
      + vpc_id                 = (known after apply)
    }

  # module.network.aws_route_table.private["us-east-2a"] will be created
  + resource "aws_route_table" "private" {
      + arn              = (known after apply)
      + id               = (known after apply)
      + owner_id         = (known after apply)
      + propagating_vgws = (known after apply)
      + route            = (known after apply)
      + tags             = {
          + "ManagedBy" = "terraform"
          + "Module"    = "network"
          + "Name"      = "datalake-dev-private-rt-us-east-2a"
        }
      + tags_all         = {
          + "Environment" = "dev"
          + "ManagedBy"   = "terraform"
          + "Module"      = "network"
          + "Name"        = "datalake-dev-private-rt-us-east-2a"
          + "Project"     = "data-engineering-checkpoint"
        }
      + vpc_id           = (known after apply)
    }

  # module.network.aws_route_table.private["us-east-2b"] will be created
  + resource "aws_route_table" "private" {
      + arn              = (known after apply)
      + id               = (known after apply)
      + owner_id         = (known after apply)
      + propagating_vgws = (known after apply)
      + route            = (known after apply)
      + tags             = {
          + "ManagedBy" = "terraform"
          + "Module"    = "network"
          + "Name"      = "datalake-dev-private-rt-us-east-2b"
        }
      + tags_all         = {
          + "Environment" = "dev"
          + "ManagedBy"   = "terraform"
          + "Module"      = "network"
          + "Name"        = "datalake-dev-private-rt-us-east-2b"
          + "Project"     = "data-engineering-checkpoint"
        }
      + vpc_id           = (known after apply)
    }

  # module.network.aws_route_table_association.private["us-east-2a"] will be created
  + resource "aws_route_table_association" "private" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # module.network.aws_route_table_association.private["us-east-2b"] will be created
  + resource "aws_route_table_association" "private" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # module.network.aws_subnet.private["us-east-2a"] will be created
  + resource "aws_subnet" "private" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "us-east-2a"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.0.1.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = false
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + tags                                           = {
          + "ManagedBy" = "terraform"
          + "Module"    = "network"
          + "Name"      = "datalake-dev-private-us-east-2a"
          + "Tier"      = "private"
        }
      + tags_all                                       = {
          + "Environment" = "dev"
          + "ManagedBy"   = "terraform"
          + "Module"      = "network"
          + "Name"        = "datalake-dev-private-us-east-2a"
          + "Project"     = "data-engineering-checkpoint"
          + "Tier"        = "private"
        }
      + vpc_id                                         = (known after apply)
    }

  # module.network.aws_subnet.private["us-east-2b"] will be created
  + resource "aws_subnet" "private" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "us-east-2b"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.0.2.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = false
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + tags                                           = {
          + "ManagedBy" = "terraform"
          + "Module"    = "network"
          + "Name"      = "datalake-dev-private-us-east-2b"
          + "Tier"      = "private"
        }
      + tags_all                                       = {
          + "Environment" = "dev"
          + "ManagedBy"   = "terraform"
          + "Module"      = "network"
          + "Name"        = "datalake-dev-private-us-east-2b"
          + "Project"     = "data-engineering-checkpoint"
          + "Tier"        = "private"
        }
      + vpc_id                                         = (known after apply)
    }

  # module.network.aws_vpc.this will be created
  + resource "aws_vpc" "this" {
      + arn                                  = (known after apply)
      + cidr_block                           = "10.0.0.0/16"
      + default_network_acl_id               = (known after apply)
      + default_route_table_id               = (known after apply)
      + default_security_group_id            = (known after apply)
      + dhcp_options_id                      = (known after apply)
      + enable_dns_hostnames                 = true
      + enable_dns_support                   = true
      + enable_network_address_usage_metrics = (known after apply)
      + id                                   = (known after apply)
      + instance_tenancy                     = "default"
      + ipv6_association_id                  = (known after apply)
      + ipv6_cidr_block                      = (known after apply)
      + ipv6_cidr_block_network_border_group = (known after apply)
      + main_route_table_id                  = (known after apply)
      + owner_id                             = (known after apply)
      + tags                                 = {
          + "ManagedBy" = "terraform"
          + "Module"    = "network"
          + "Name"      = "datalake-dev-vpc"
        }
      + tags_all                             = {
          + "Environment" = "dev"
          + "ManagedBy"   = "terraform"
          + "Module"      = "network"
          + "Name"        = "datalake-dev-vpc"
          + "Project"     = "data-engineering-checkpoint"
        }
    }

  # module.network.aws_vpc_endpoint.s3 will be created
  + resource "aws_vpc_endpoint" "s3" {
      + arn                   = (known after apply)
      + cidr_blocks           = (known after apply)
      + dns_entry             = (known after apply)
      + id                    = (known after apply)
      + ip_address_type       = (known after apply)
      + network_interface_ids = (known after apply)
      + owner_id              = (known after apply)
      + policy                = (known after apply)
      + prefix_list_id        = (known after apply)
      + private_dns_enabled   = (known after apply)
      + requester_managed     = (known after apply)
      + route_table_ids       = (known after apply)
      + security_group_ids    = (known after apply)
      + service_name          = "com.amazonaws.us-east-2.s3"
      + service_region        = (known after apply)
      + state                 = (known after apply)
      + subnet_ids            = (known after apply)
      + tags                  = {
          + "ManagedBy" = "terraform"
          + "Module"    = "network"
          + "Name"      = "datalake-dev-s3-gateway-endpoint"
        }
      + tags_all              = {
          + "Environment" = "dev"
          + "ManagedBy"   = "terraform"
          + "Module"      = "network"
          + "Name"        = "datalake-dev-s3-gateway-endpoint"
          + "Project"     = "data-engineering-checkpoint"
        }
      + vpc_endpoint_type     = "Gateway"
      + vpc_id                = (known after apply)

      + dns_options (known after apply)

      + subnet_configuration (known after apply)
    }

Plan: 14 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + audit_role_arn                      = (known after apply)
  + private_route_table_ids             = [
      + (known after apply),
      + (known after apply),
    ]
  + private_subnet_ids                  = [
      + (known after apply),
      + (known after apply),
    ]
  + processing_role_arn                 = (known after apply)
  + s3_gateway_endpoint_id              = (known after apply)
  + s3_gateway_endpoint_route_table_ids = (known after apply)
  + vpc_id                              = (known after apply)

─────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't
guarantee to take exactly these actions if you run "terraform apply" now.
Releasing state lock. This may take a few moments...
```
