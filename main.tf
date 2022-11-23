data "aws_partition" "current" {}

locals {
  create_cluster = var.aurora_db.create_cluster && var.aurora_db.putin_khuylo

  port = coalesce(var.aurora_db.port, (var.aurora_db.engine == "aurora-postgresql" ? 5432 : 3306))

  internal_db_subnet_group_name = try(coalesce(var.aurora_db.db_subnet_group_name, var.aurora_db.name), "")
  db_subnet_group_name          = var.aurora_db.create_db_subnet_group ? try(aws_db_subnet_group.this[0].name, null) : local.internal_db_subnet_group_name

  cluster_parameter_group_name = try(coalesce(var.aurora_db.db_cluster_parameter_group_name, var.aurora_db.name), null)
  db_parameter_group_name      = try(coalesce(var.aurora_db.db_parameter_group_name, var.aurora_db.name), null)

  master_password  = local.create_cluster && var.aurora_db.create_random_password ? random_password.master_password[0].result : var.aurora_db.master_password
  backtrack_window = (var.aurora_db.engine == "aurora-mysql" || var.aurora_db.engine == "aurora") && var.aurora_db.engine_mode != "serverless" ? var.aurora_db.backtrack_window : 0

  is_serverless = var.aurora_db.engine_mode == "serverless"

  final_snapshot_identifier_prefix = "${var.aurora_db.final_snapshot_identifier_prefix}-${var.aurora_db.name}-${try(random_id.snapshot_identifier[0].hex, "")}"
}

################################################################################
# Random Password & Snapshot ID
################################################################################

resource "random_password" "master_password" {
  count = local.create_cluster && var.aurora_db.create_random_password ? 1 : 0

  length  = var.aurora_db.random_password_length
  special = false
}

resource "random_id" "snapshot_identifier" {
  count = local.create_cluster && !var.aurora_db.skip_final_snapshot ? 1 : 0

  keepers = {
    id = var.aurora_db.name
  }

  byte_length = 4
}

################################################################################
# DB Subnet Group
################################################################################

resource "aws_db_subnet_group" "this" {
  count = local.create_cluster && var.aurora_db.create_db_subnet_group ? 1 : 0

  name        = local.internal_db_subnet_group_name
  description = "For Aurora cluster ${var.aurora_db.name}"
  subnet_ids  = var.aurora_db.subnets

  tags = var.aurora_db.tags
}

################################################################################
# Cluster
################################################################################

resource "aws_rds_cluster" "this" {
  count = local.create_cluster ? 1 : 0

  allocated_storage                   = var.aurora_db.allocated_storage
  allow_major_version_upgrade         = var.aurora_db.allow_major_version_upgrade
  apply_immediately                   = var.aurora_db.apply_immediately
  availability_zones                  = var.aurora_db.availability_zones
  backup_retention_period             = var.aurora_db.backup_retention_period
  backtrack_window                    = local.backtrack_window
  cluster_identifier                  = var.aurora_db.cluster_use_name_prefix ? null : var.aurora_db.name
  cluster_identifier_prefix           = var.aurora_db.cluster_use_name_prefix ? "${var.aurora_db.name}-" : null
  cluster_members                     = var.aurora_db.cluster_members
  copy_tags_to_snapshot               = var.aurora_db.copy_tags_to_snapshot
  database_name                       = var.aurora_db.is_primary_cluster ? var.aurora_db.database_name : null
  db_cluster_instance_class           = var.aurora_db.db_cluster_instance_class
  db_cluster_parameter_group_name     = var.aurora_db.create_db_cluster_parameter_group ? aws_rds_cluster_parameter_group.this[0].id : var.aurora_db.db_cluster_parameter_group_name
  db_instance_parameter_group_name    = var.aurora_db.allow_major_version_upgrade ? var.aurora_db.db_cluster_db_instance_parameter_group_name : null
  db_subnet_group_name                = local.db_subnet_group_name
  deletion_protection                 = var.aurora_db.deletion_protection
  enable_global_write_forwarding      = var.aurora_db.enable_global_write_forwarding
  enabled_cloudwatch_logs_exports     = var.aurora_db.enabled_cloudwatch_logs_exports
  enable_http_endpoint                = var.aurora_db.enable_http_endpoint
  engine                              = var.aurora_db.engine
  engine_mode                         = var.aurora_db.engine_mode
  engine_version                      = var.aurora_db.engine_version
  final_snapshot_identifier           = var.aurora_db.skip_final_snapshot ? null : local.final_snapshot_identifier_prefix
  global_cluster_identifier           = var.aurora_db.global_cluster_identifier
  iam_database_authentication_enabled = var.aurora_db.iam_database_authentication_enabled
  # iam_roles has been removed from this resource and instead will be used with aws_rds_cluster_role_association below to avoid conflicts per docs
  iops                          = var.aurora_db.iops
  kms_key_id                    = var.aurora_db.kms_key_id
  master_password               = var.aurora_db.is_primary_cluster ? local.master_password : null
  master_username               = var.aurora_db.is_primary_cluster ? var.aurora_db.master_username : null
  network_type                  = var.aurora_db.network_type
  port                          = local.port
  preferred_backup_window       = local.is_serverless ? null : var.aurora_db.preferred_backup_window
  preferred_maintenance_window  = local.is_serverless ? null : var.aurora_db.preferred_maintenance_window
  replication_source_identifier = var.aurora_db.replication_source_identifier

  dynamic "restore_to_point_in_time" {
    for_each = length(var.aurora_db.restore_to_point_in_time) > 0 ? [var.aurora_db.restore_to_point_in_time] : []

    content {
      restore_to_time            = try(restore_to_point_in_time.value.restore_to_time, null)
      restore_type               = try(restore_to_point_in_time.value.restore_type, null)
      source_cluster_identifier  = restore_to_point_in_time.value.source_cluster_identifier
      use_latest_restorable_time = try(restore_to_point_in_time.value.use_latest_restorable_time, null)
    }
  }

  dynamic "s3_import" {
    for_each = length(var.aurora_db.s3_import) > 0 && !local.is_serverless ? [var.aurora_db.s3_import] : []

    content {
      bucket_name           = s3_import.value.bucket_name
      bucket_prefix         = try(s3_import.value.bucket_prefix, null)
      ingestion_role        = s3_import.value.ingestion_role
      source_engine         = "mysql"
      source_engine_version = s3_import.value.source_engine_version
    }
  }

  dynamic "scaling_configuration" {
    for_each = length(var.aurora_db.scaling_configuration) > 0 && local.is_serverless ? [var.aurora_db.scaling_configuration] : []

    content {
      auto_pause               = try(scaling_configuration.value.auto_pause, null)
      max_capacity             = try(scaling_configuration.value.max_capacity, null)
      min_capacity             = try(scaling_configuration.value.min_capacity, null)
      seconds_until_auto_pause = try(scaling_configuration.value.seconds_until_auto_pause, null)
      timeout_action           = try(scaling_configuration.value.timeout_action, null)
    }
  }

  dynamic "serverlessv2_scaling_configuration" {
    for_each = length(var.aurora_db.serverlessv2_scaling_configuration) > 0 && var.aurora_db.engine_mode == "provisioned" ? [var.aurora_db.serverlessv2_scaling_configuration] : []

    content {
      max_capacity = serverlessv2_scaling_configuration.value.max_capacity
      min_capacity = serverlessv2_scaling_configuration.value.min_capacity
    }
  }

  skip_final_snapshot    = var.aurora_db.skip_final_snapshot
  snapshot_identifier    = var.aurora_db.snapshot_identifier
  source_region          = var.aurora_db.source_region
  storage_encrypted      = var.aurora_db.storage_encrypted
  storage_type           = var.aurora_db.storage_type
  tags                   = merge(var.aurora_db.tags, var.aurora_db.cluster_tags)
  vpc_security_group_ids = compact(concat([try(aws_security_group.this[0].id, "")], var.aurora_db.vpc_security_group_ids))

  timeouts {
    create = try(var.aurora_db.cluster_timeouts.create, null)
    update = try(var.aurora_db.cluster_timeouts.update, null)
    delete = try(var.aurora_db.cluster_timeouts.delete, null)
  }

  lifecycle {
    ignore_changes = [
      # See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster#replication_source_identifier
      # Since this is used either in read-replica clusters or global clusters, this should be acceptable to specify
      replication_source_identifier,
      # See docs here https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_global_cluster#new-global-cluster-from-existing-db-cluster
      global_cluster_identifier,
    ]
  }
}

################################################################################
# Cluster Instance(s)
################################################################################

resource "aws_rds_cluster_instance" "this" {
  for_each = { for k, v in var.aurora_db.instances : k => v if local.create_cluster && !local.is_serverless }

  apply_immediately                     = try(each.value.apply_immediately, var.aurora_db.apply_immediately)
  auto_minor_version_upgrade            = try(each.value.auto_minor_version_upgrade, var.aurora_db.auto_minor_version_upgrade)
  availability_zone                     = try(each.value.availability_zone, null)
  ca_cert_identifier                    = var.aurora_db.ca_cert_identifier
  cluster_identifier                    = aws_rds_cluster.this[0].id
  copy_tags_to_snapshot                 = try(each.value.copy_tags_to_snapshot, var.aurora_db.copy_tags_to_snapshot)
  db_parameter_group_name               = var.aurora_db.create_db_parameter_group ? aws_db_parameter_group.this[0].id : var.aurora_db.db_parameter_group_name
  db_subnet_group_name                  = local.db_subnet_group_name
  engine                                = var.aurora_db.engine
  engine_version                        = var.aurora_db.engine_version
  identifier                            = var.aurora_db.instances_use_identifier_prefix ? null : try(each.value.identifier, "${var.aurora_db.name}-${each.key}")
  identifier_prefix                     = var.aurora_db.instances_use_identifier_prefix ? try(each.value.identifier_prefix, "${var.aurora_db.name}-${each.key}-") : null
  instance_class                        = try(each.value.instance_class, var.aurora_db.instance_class)
  monitoring_interval                   = try(each.value.monitoring_interval, var.aurora_db.monitoring_interval)
  monitoring_role_arn                   = var.aurora_db.create_monitoring_role ? try(aws_iam_role.rds_enhanced_monitoring[0].arn, null) : var.aurora_db.monitoring_role_arn
  performance_insights_enabled          = try(each.value.performance_insights_enabled, var.aurora_db.performance_insights_enabled)
  performance_insights_kms_key_id       = try(each.value.performance_insights_kms_key_id, var.aurora_db.performance_insights_kms_key_id)
  performance_insights_retention_period = try(each.value.performance_insights_retention_period, var.aurora_db.performance_insights_retention_period)
  # preferred_backup_window - is set at the cluster level and will error if provided here
  preferred_maintenance_window = try(each.value.preferred_maintenance_window, var.aurora_db.preferred_maintenance_window)
  promotion_tier               = try(each.value.promotion_tier, null)
  publicly_accessible          = try(each.value.publicly_accessible, var.aurora_db.publicly_accessible)
  tags                         = merge(var.aurora_db.tags, try(each.value.tags, {}))

  timeouts {
    create = try(var.aurora_db.instance_timeouts.create, null)
    update = try(var.aurora_db.instance_timeouts.update, null)
    delete = try(var.aurora_db.instance_timeouts.delete, null)
  }
}

################################################################################
# Cluster Endpoint(s)
################################################################################

resource "aws_rds_cluster_endpoint" "this" {
  for_each = { for k, v in var.aurora_db.endpoints : k => v if local.create_cluster && !local.is_serverless }

  cluster_endpoint_identifier = each.value.identifier
  cluster_identifier          = aws_rds_cluster.this[0].id
  custom_endpoint_type        = each.value.type
  excluded_members            = try(each.value.excluded_members, null)
  static_members              = try(each.value.static_members, null)
  tags                        = merge(var.aurora_db.tags, try(each.value.tags, {}))

  depends_on = [
    aws_rds_cluster_instance.this
  ]
}

################################################################################
# Cluster IAM Roles
################################################################################

resource "aws_rds_cluster_role_association" "this" {
  for_each = { for k, v in var.aurora_db.iam_roles : k => v if local.create_cluster }

  db_cluster_identifier = aws_rds_cluster.this[0].id
  feature_name          = each.value.feature_name
  role_arn              = each.value.role_arn
}

################################################################################
# Enhanced Monitoring
################################################################################

data "aws_iam_policy_document" "monitoring_rds_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = local.create_cluster && var.aurora_db.create_monitoring_role && var.aurora_db.monitoring_interval > 0 ? 1 : 0

  name        = var.aurora_db.iam_role_use_name_prefix ? null : var.aurora_db.iam_role_name
  name_prefix = var.aurora_db.iam_role_use_name_prefix ? "${var.aurora_db.iam_role_name}-" : null
  description = var.aurora_db.iam_role_description
  path        = var.aurora_db.iam_role_path

  assume_role_policy    = data.aws_iam_policy_document.monitoring_rds_assume_role.json
  managed_policy_arns   = var.aurora_db.iam_role_managed_policy_arns
  permissions_boundary  = var.aurora_db.iam_role_permissions_boundary
  force_detach_policies = var.aurora_db.iam_role_force_detach_policies
  max_session_duration  = var.aurora_db.iam_role_max_session_duration

  tags = var.aurora_db.tags
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count = local.create_cluster && var.aurora_db.create_monitoring_role && var.aurora_db.monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

################################################################################
# Autoscaling
################################################################################

resource "aws_appautoscaling_target" "this" {
  count = local.create_cluster && var.aurora_db.autoscaling_enabled && !local.is_serverless ? 1 : 0

  max_capacity       = var.aurora_db.autoscaling_max_capacity
  min_capacity       = var.aurora_db.autoscaling_min_capacity
  resource_id        = "cluster:${aws_rds_cluster.this[0].cluster_identifier}"
  scalable_dimension = "rds:cluster:ReadReplicaCount"
  service_namespace  = "rds"
}

resource "aws_appautoscaling_policy" "this" {
  count = local.create_cluster && var.aurora_db.autoscaling_enabled && !local.is_serverless ? 1 : 0

  name               = var.aurora_db.autoscaling_policy_name
  policy_type        = "TargetTrackingScaling"
  resource_id        = "cluster:${aws_rds_cluster.this[0].cluster_identifier}"
  scalable_dimension = "rds:cluster:ReadReplicaCount"
  service_namespace  = "rds"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = var.aurora_db.predefined_metric_type
    }

    scale_in_cooldown  = var.aurora_db.autoscaling_scale_in_cooldown
    scale_out_cooldown = var.aurora_db.autoscaling_scale_out_cooldown
    target_value       = var.aurora_db.predefined_metric_type == "RDSReaderAverageCPUUtilization" ? var.aurora_db.autoscaling_target_cpu : var.aurora_db.autoscaling_target_connections
  }

  depends_on = [
    aws_appautoscaling_target.this
  ]
}

################################################################################
# Security Group
################################################################################

resource "aws_security_group" "this" {
  count = local.create_cluster && var.aurora_db.create_security_group ? 1 : 0

  name        = var.aurora_db.security_group_use_name_prefix ? null : var.aurora_db.name
  name_prefix = var.aurora_db.security_group_use_name_prefix ? "${var.aurora_db.name}-" : null
  vpc_id      = var.aurora_db.vpc_id
  description = coalesce(var.aurora_db.security_group_description, "Control traffic to/from RDS Aurora ${var.aurora_db.name}")

  tags = merge(var.aurora_db.tags, var.aurora_db.security_group_tags, { Name = var.aurora_db.name })

  lifecycle {
    create_before_destroy = true
  }
}

# TODO - change to map of ingress rules under one resource at next breaking change
resource "aws_security_group_rule" "default_ingress" {
  count = local.create_cluster && var.aurora_db.create_security_group ? length(var.aurora_db.allowed_security_groups) : 0

  description = "From allowed SGs"

  type                     = "ingress"
  from_port                = local.port
  to_port                  = local.port
  protocol                 = "tcp"
  source_security_group_id = element(var.aurora_db.allowed_security_groups, count.index)
  security_group_id        = aws_security_group.this[0].id
}

# TODO - change to map of ingress rules under one resource at next breaking change
resource "aws_security_group_rule" "cidr_ingress" {
  count = local.create_cluster && var.aurora_db.create_security_group && length(var.aurora_db.allowed_cidr_blocks) > 0 ? 1 : 0

  description = "From allowed CIDRs"

  type              = "ingress"
  from_port         = local.port
  to_port           = local.port
  protocol          = "tcp"
  cidr_blocks       = var.aurora_db.allowed_cidr_blocks
  security_group_id = aws_security_group.this[0].id
}

resource "aws_security_group_rule" "egress" {
  for_each = local.create_cluster && var.aurora_db.create_security_group ? var.aurora_db.security_group_egress_rules : {}

  # required
  type              = "egress"
  from_port         = try(each.value.from_port, local.port)
  to_port           = try(each.value.to_port, local.port)
  protocol          = "tcp"
  security_group_id = aws_security_group.this[0].id

  # optional
  cidr_blocks              = try(each.value.cidr_blocks, null)
  description              = try(each.value.description, null)
  ipv6_cidr_blocks         = try(each.value.ipv6_cidr_blocks, null)
  prefix_list_ids          = try(each.value.prefix_list_ids, null)
  source_security_group_id = try(each.value.source_security_group_id, null)
}

################################################################################
# Cluster Parameter Group
################################################################################

resource "aws_rds_cluster_parameter_group" "this" {
  count = local.create_cluster && var.aurora_db.create_db_cluster_parameter_group ? 1 : 0

  name        = var.aurora_db.db_cluster_parameter_group_use_name_prefix ? null : local.cluster_parameter_group_name
  name_prefix = var.aurora_db.db_cluster_parameter_group_use_name_prefix ? "${local.cluster_parameter_group_name}-" : null
  description = var.aurora_db.db_cluster_parameter_group_description
  family      = var.aurora_db.db_cluster_parameter_group_family

  dynamic "parameter" {
    for_each = var.aurora_db.db_cluster_parameter_group_parameters

    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = try(parameter.value.apply_method, "immediate")
    }
  }

  tags = var.aurora_db.tags
}

################################################################################
# DB Parameter Group
################################################################################

resource "aws_db_parameter_group" "this" {
  count = local.create_cluster && var.aurora_db.create_db_parameter_group ? 1 : 0

  name        = var.aurora_db.db_parameter_group_use_name_prefix ? null : local.db_parameter_group_name
  name_prefix = var.aurora_db.db_parameter_group_use_name_prefix ? "${local.db_parameter_group_name}-" : null
  description = var.aurora_db.db_parameter_group_description
  family      = var.aurora_db.db_parameter_group_family

  dynamic "parameter" {
    for_each = var.aurora_db.db_parameter_group_parameters

    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = try(parameter.value.apply_method, "immediate")
    }
  }

  tags = var.aurora_db.tags
}
