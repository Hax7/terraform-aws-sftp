## Managed By : CloudDrove
## Description : This Script is used to create Transfer Server, Transfer User And  TransferSSK_KEY.
## Copyright @ CloudDrove. All Right Reserved.

<<<<<<< HEAD
##----------------------------------------------------------------------------------
## Labels module callled that will be used for naming and tags.
##----------------------------------------------------------------------------------

=======
#Module      : labels
#Description : This terraform module is desigzned to generate consistent label names and tags
#              for resources. You can use terraform-labels to implement a strict naming
#              convention.
>>>>>>> a3ef3653b9f6af985f2c162e959e49623fcee0c2
module "labels" {
  source  = "clouddrove/labels/aws"
  version = "1.3.0"

  name        = var.name
  repository  = var.repository
  environment = var.environment
  managedby   = var.managedby
  attributes  = var.attributes
  label_order = var.label_order
}

##----------------------------------------------------------------------------------
# LOCALS
##----------------------------------------------------------------------------------
locals {
  count         = var.enabled
  s3_arn_prefix = "arn:${one(data.aws_partition.default[*].partition)}:s3:::"
  is_vpc        = var.vpc_id != null

  user_names = length(var.sftp_users) > 0 ? [for user in var.sftp_users : user.username] : []

  user_names_map = length(var.sftp_users) > 0 ? {
    for user in var.sftp_users :
    user.username => merge(user, {
      s3_bucket_arn = lookup(user, "s3_bucket_name", null) != null ? "${local.s3_arn_prefix}${lookup(user, "s3_bucket_name")}" : one(data.aws_s3_bucket.landing[*].arn)
    })
  } : {}
}

data "aws_partition" "default" {
  count = var.enabled ? 1 : 0
}

data "aws_s3_bucket" "landing" {
  count = var.enabled ? 1 : 0

  bucket = var.s3_bucket_name
}

##----------------------------------------------------------------------------------
# IAM POLICIES
##----------------------------------------------------------------------------------

# Module      : IAM POLICY
# Description : This data source can be used to fetch information about a specific IAM role.

data "aws_iam_policy_document" "transfer_server_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
  }
}

<<<<<<< HEAD
data "aws_iam_policy_document" "transfer_server_assume_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:*",
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "s3_access_for_sftp_users" {
  for_each = var.enabled ? local.user_names_map : {}
  statement {
    sid    = "AllowListingOfUserFolder"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      each.value.s3_bucket_arn,
    ]
  }

  statement {
    sid    = "HomeDirObjectAccess"
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetObjectVersion",
      "s3:GetObjectACL",
      "s3:PutObjectACL"
    ]

    resources = [
      var.restricted_home ? "${each.value.s3_bucket_arn}/${each.value.user_name}/*" : "${each.value.s3_bucket_arn}/*"
    ]
  }
}


data "aws_iam_policy_document" "logging" {

  statement {
    sid    = "CloudWatchAccessForAWSTransfer"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:CreateLogGroup",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "assume_role_policy" {
  count = var.enabled ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
  }
}

##----------------------------------------------------------------------------------
=======
>>>>>>> a3ef3653b9f6af985f2c162e959e49623fcee0c2
# Module      : IAM ROLE
# Description : This data source can be used to fetch information about a specific IAM role.
##----------------------------------------------------------------------------------

resource "aws_iam_role" "s3_access_for_sftp_users" {
  for_each = var.enabled ? local.user_names_map : {}

  name                = module.labels.id
  assume_role_policy  = join("", data.aws_iam_policy_document.assume_role_policy[*].json)
  managed_policy_arns = [aws_iam_policy.s3_access_for_sftp_users[each.value.user_name].arn]
}

resource "aws_iam_policy" "s3_access_for_sftp_users" {
  for_each = var.enabled ? local.user_names_map : {}

  name   = module.labels.id
  policy = data.aws_iam_policy_document.s3_access_for_sftp_users[each.value.user_name].json

  tags = module.labels.tags
}

<<<<<<< HEAD
##----------------------------------------------------------------------------------
# Module      : IAM ROLE POLICY
# Description : Provides an IAM role policy.
##----------------------------------------------------------------------------------
resource "aws_iam_policy" "logging" {
  count = var.enabled ? 1 : 0

  name   = module.labels.id
  policy = join("", data.aws_iam_policy_document.logging[*].json)

  tags = module.labels.tags
}

resource "aws_iam_role" "logging" {
  count = var.enabled ? 1 : 0

  name                = module.labels.id
  assume_role_policy  = join("", data.aws_iam_policy_document.assume_role_policy[*].json)
  managed_policy_arns = [join("", aws_iam_policy.logging[*].arn)]

  tags = module.labels.tags
=======
# Module      : AWS TRANSFER SERVER
# Description : Provides a AWS Transfer Server resource.
resource "aws_transfer_server" "transfer_server" {
  count = var.enable_sftp && var.endpoint_type == "PUBLIC" ? 1 : 0

  identity_provider_type = var.identity_provider_type
  logging_role           = join("", aws_iam_role.transfer_server_role[*].arn)
  force_destroy          = false
  tags                   = module.labels.tags
  endpoint_type          = var.endpoint_type
>>>>>>> a3ef3653b9f6af985f2c162e959e49623fcee0c2
}

##----------------------------------------------------------------------------------
# Module      : AWS TRANSFER SERVER
# Description : Provides a AWS Transfer Server resource.
##----------------------------------------------------------------------------------

resource "aws_transfer_server" "transfer_server" {
  count                  = var.enable_sftp ? 1 : 0
  identity_provider_type = var.identity_provider_type
<<<<<<< HEAD
  protocols              = ["SFTP"]
  domain                 = var.domain
  force_destroy          = var.force_destroy
  endpoint_type          = local.is_vpc ? "VPC" : "PUBLIC"
  security_policy_name   = var.security_policy_name
  logging_role           = join("", aws_iam_role.logging[*].arn)
=======
  logging_role           = join("", aws_iam_role.transfer_server_role[*].arn)
  force_destroy          = false
>>>>>>> a3ef3653b9f6af985f2c162e959e49623fcee0c2
  tags                   = module.labels.tags
  dynamic "workflow_details" {
    for_each = var.enable_workflow ? [1] : []
    content {
      on_upload {
        execution_role = var.workflow_details.on_upload.execution_role
        workflow_id    = var.workflow_details.on_upload.workflow_id
      }
    }
  }
  dynamic "endpoint_details" {
    for_each = local.is_vpc ? [1] : []
    content {
      subnet_ids             = var.subnet_ids
      security_group_ids     = var.vpc_security_group_ids
      vpc_id                 = var.vpc_id
      address_allocation_ids = var.eip_enabled ? aws_eip.sftp.*.id : var.address_allocation_ids
    }
  }
  lifecycle {
    ignore_changes = [tags]
  }

}

##----------------------------------------------------------------------------------
# Module      : AWS TRANSFER USER
# Description : Provides a AWS Transfer User resource.
##----------------------------------------------------------------------------------

resource "aws_transfer_user" "transfer_server_user" {
  for_each = var.enabled ? { for user in var.sftp_users : user.username => user } : {}

  server_id           = join("", aws_transfer_server.transfer_server[*].id)
  role                = aws_iam_role.s3_access_for_sftp_users[each.value.user_name].arn
  user_name           = each.value.user_name
  home_directory_type = lookup(each.value, "home_directory_type", null) != null ? lookup(each.value, "home_directory_type") : (var.restricted_home ? "LOGICAL" : "PATH")
  home_directory      = lookup(each.value, "home_directory", null) != null ? lookup(each.value, "home_directory") : (!var.restricted_home ? "/${lookup(each.value, "s3_bucket_name", var.s3_bucket_name)}" : null)
  tags                = module.labels.tags

<<<<<<< HEAD
  dynamic "home_directory_mappings" {
    for_each = var.restricted_home ? (
      lookup(each.value, "home_directory_mappings", null) != null ? lookup(each.value, "home_directory_mappings") : {}
    ) : {}

    content {
      entry  = home_directory_mappings.key
      target = home_directory_mappings.value
    }
  }
=======
  server_id      = var.endpoint_type == "VPC" ? join("", aws_transfer_server.transfer_server_vpc[*].id) : join("", aws_transfer_server.transfer_server[*].id)
  user_name      = var.user_name
  role           = join("", aws_iam_role.transfer_server_role[*].arn)
  home_directory = format("/%s/%s", var.s3_bucket_id, var.sub_folder)
  tags           = module.labels.tags
>>>>>>> a3ef3653b9f6af985f2c162e959e49623fcee0c2
}

##----------------------------------------------------------------------------------
# Module      : AWS TRANSFER SERVER SSH
# Description : Provides a AWS Transfer SERVER SSH resource.
##----------------------------------------------------------------------------------

resource "aws_transfer_ssh_key" "transfer_server_ssh_key" {
  count     = var.enabled ? length(var.sftp_users) : 0
  server_id = join("", aws_transfer_server.transfer_server[*].id)
  user_name = aws_transfer_user.transfer_server_user[count.index].user_name
  body      = aws_transfer_user.transfer_server_user[count.index].public_key
}


<<<<<<< HEAD
##----------------------------------------------------------------------------------
# Module      : AWS ELASTIC IP
# Description : Provides a AWS ELASTIC IP.
##----------------------------------------------------------------------------------

resource "aws_eip" "sftp" {
  count = var.enabled && var.eip_enabled ? length(var.subnet_ids) : 0
  vpc   = local.is_vpc
  tags  = module.labels.tags
}

##----------------------------------------------------------------------------------
# Module      : Custom Domain
# Description : Provides a Custom Domain
##----------------------------------------------------------------------------------

resource "aws_route53_record" "custom_domain" {
  count = var.enabled && length(var.domain_name) > 0 && length(var.zone_id) > 0 ? 1 : 0

  name    = var.domain_name
  zone_id = var.zone_id
  type    = "CNAME"
  ttl     = "300"

  records = [
    join("", aws_transfer_server.transfer_server[*].endpoint)
  ]
=======
  server_id = join("", aws_transfer_server.transfer_server[*].id)
  user_name = join("", aws_transfer_user.transfer_server_user[*].user_name)
  body      = var.public_key
>>>>>>> a3ef3653b9f6af985f2c162e959e49623fcee0c2
}