variable "aurora_db" {
  description = "AWS Aurora Database to be created"
  type = object({
    # "Name used across resources created"
    name = optional(string, "")

    # "A map of tags to add to all resources"
    tags = optional(map(string), {})

    # "Determines whether to create random password for RDS primary cluster"
    create_random_password = optional(bool, true)

    # "Length of random password to create. Defaults to `10`"
    random_password_length = optional(number, 10)

    # "Determines whether to create the database subnet group or use existing"
    create_db_subnet_group = optional(bool, true)

    # "The name of the subnet group name (existing or created)"
    db_subnet_group_name = optional(string, "")

    # "List of subnet IDs used by database subnet group created"
    subnets = optional(list(string), [])

    # "The type of network stack to use (IPV4 or DUAL)"
    network_type = optional(string, null)

    # "Whether cluster should be created (affects nearly all resources)"
    create_cluster = optional(bool, true)

    # "Determines whether cluster is primary cluster with writer instance (set to `false` for global cluster and replica clusters)"
    is_primary_cluster = optional(bool, true)

    # "Whether to use `name` as a prefix for the cluster"
    cluster_use_name_prefix = optional(bool, false)

    # "The amount of storage in gibibytes (GiB) to allocate to each DB instance in the Multi-AZ DB cluster. (This setting is required to create a Multi-AZ DB cluster)"
    allocated_storage = optional(number, null)

    # "Enable to allow major engine version upgrades when changing engine versions. Defaults to `false`"
    allow_major_version_upgrade = optional(bool, false)

    # "Specifies whether any cluster modifications are applied immediately, or during the next maintenance window. Default is `false`"
    apply_immediately = optional(bool, null)

    # "List of EC2 Availability Zones for the DB cluster storage where DB cluster instances can be created. RDS automatically assigns 3 AZs if less than 3 AZs are configured, which will show as a difference requiring resource recreation next Terraform apply"
    availability_zones = optional(list(string), null)

    # "The days to retain backups for. Default `7`"
    backup_retention_period = optional(number, 7)

    # "The target backtrack window, in seconds. Only available for `aurora` engine currently. To disable backtracking, set this value to 0. Must be between 0 and 259200 (72 hours)"
    backtrack_window = optional(number, null)

    # "List of RDS Instances that are a part of this cluster"
    cluster_members = optional(list(string), null)

    # "Copy all Cluster `tags` to snapshots"
    copy_tags_to_snapshot = optional(bool, null)

    # "Name for an automatically created database on cluster creation"
    database_name = optional(string, null)

    # "The compute and memory capacity of each DB instance in the Multi-AZ DB cluster, for example db.m6g.xlarge. Not all DB instance classes are available in all AWS Regions, or for all database engines"
    db_cluster_instance_class = optional(string, null)

    # "Instance parameter group to associate with all instances of the DB cluster. The `db_cluster_db_instance_parameter_group_name` is only valid in combination with `allow_major_version_upgrade`"
    db_cluster_db_instance_parameter_group_name = optional(string, null)

    # "If the DB instance should have deletion protection enabled. The database can't be deleted when this value is set to `true`. The default is `false`"
    deletion_protection = optional(bool, null)

    # "Whether cluster should forward writes to an associated global cluster. Applied to secondary clusters to enable them to forward writes to an `aws_rds_global_cluster`'s primary cluster"
    enable_global_write_forwarding = optional(bool, null)

    # "Set of log types to export to cloudwatch. If omitted, no logs will be exported. The following log types are supported: `audit`, `error`, `general`, `slowquery`, `postgresql`"
    enabled_cloudwatch_logs_exports = optional(list(string), [])

    # "Enable HTTP endpoint (data API). Only valid when engine_mode is set to `serverless`"
    enable_http_endpoint = optional(bool, null)

    # "The name of the database engine to be used for this DB cluster. Defaults to `aurora`. Valid Values: `aurora`, `aurora-mysql`, `aurora-postgresql`"
    engine = optional(string, null)

    # "The database engine mode. Valid values: `global`, `multimaster`, `parallelquery`, `provisioned`, `serverless`. Defaults to: `provisioned`"
    engine_mode = optional(string, null)

    # "The database engine version. Updating this argument results in an outage"
    engine_version = optional(string, null)

    # "The prefix name to use when creating a final snapshot on cluster destroy; a 8 random digits are appended to name to ensure it's unique"
    final_snapshot_identifier_prefix = optional(string, "final")

    # "The global cluster identifier specified on `aws_rds_global_cluster`"
    global_cluster_identifier = optional(string, null)

    # "Specifies whether or mappings of AWS Identity and Access Management (IAM) accounts to database accounts is enabled"
    iam_database_authentication_enabled = optional(bool, null)

    # "The amount of Provisioned IOPS (input/output operations per second) to be initially allocated for each DB instance in the Multi-AZ DB cluster"
    iops = optional(number, null)

    # "The ARN for the KMS encryption key. When specifying `kms_key_id`, `storage_encrypted` needs to be set to `true`"
    kms_key_id = optional(string, null)

    # "Password for the master DB user. Note - when specifying a value here, 'create_random_password' should be set to `false`"
    master_password = optional(string, null)

    # "Username for the master DB user"
    master_username = optional(string, "root")

    # "The port on which the DB accepts connections"
    port = optional(string, null)

    # "The daily time range during which automated backups are created if automated backups are enabled using the `backup_retention_period` parameter. Time in UTC"
    preferred_backup_window = optional(string, "02:00-03:00")

    # "The weekly time range during which system maintenance can occur, in (UTC)"
    preferred_maintenance_window = optional(string, "sun:05:00-sun:06:00")

    # "ARN of a source DB cluster or DB instance if this DB cluster is to be created as a Read Replica"
    replication_source_identifier = optional(string, null)

    # "Map of nested attributes for cloning Aurora cluster"
    restore_to_point_in_time = optional(map(string), {})

    # "Configuration map used to restore from a Percona Xtrabackup in S3 (only MySQL is supported)"
    s3_import = optional(map(string), {})

    # "Map of nested attributes with scaling properties. Only valid when `engine_mode` is set to `serverless`"
    scaling_configuration = optional(map(string), {})

    # "Map of nested attributes with serverless v2 scaling properties. Only valid when `engine_mode` is set to `provisioned`"
    serverlessv2_scaling_configuration = optional(map(string), {})

    # "Determines whether a final snapshot is created before the cluster is deleted. If true is specified, no snapshot is created"
    skip_final_snapshot = optional(bool, false)

    # "Specifies whether or not to create this cluster from a snapshot. You can use either the name or ARN when specifying a DB cluster snapshot, or the ARN when specifying a DB snapshot"
    snapshot_identifier = optional(string, null)

    # "The source region for an encrypted replica DB cluster"
    source_region = optional(string, null)

    # "Specifies whether the DB cluster is encrypted. The default is `true`"
    storage_encrypted = optional(bool, true)

    # "Specifies the storage type to be associated with the DB cluster. (This setting is required to create a Multi-AZ DB cluster). Valid values: `io1`, Default: `io1`"
    storage_type = optional(string, null)

    # "A map of tags to add to only the cluster. Used for AWS Instance Scheduler tagging"
    cluster_tags = optional(map(string), {})

    # "List of VPC security groups to associate to the cluster in addition to the SG we create in this module"
    vpc_security_group_ids = optional(list(string), [])

    # "Create, update, and delete timeout configurations for the cluster"
    cluster_timeouts = optional(map(string), {})

    # "Map of cluster instances and any specific/overriding attributes to be created"
    instances = optional(any, {})

    # "Indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window. Default `true`"
    auto_minor_version_upgrade = optional(bool, null)

    # "The identifier of the CA certificate for the DB instance"
    ca_cert_identifier = optional(string, null)

    # "The name of the DB parameter group"
    db_parameter_group_name = optional(string, null)

    # "Determines whether cluster instance identifiers are used as prefixes"
    instances_use_identifier_prefix = optional(bool, false)

    # "Instance type to use at master instance. Note: if `autoscaling_enabled` is `true`, this will be the same instance class used on instances created by autoscaling"
    instance_class = optional(string, "")

    # "The interval, in seconds, between points when Enhanced Monitoring metrics are collected for instances. Set to `0` to disable. Default is `0`"
    monitoring_interval = optional(number, 0)

    # "Specifies whether Performance Insights is enabled or not"
    performance_insights_enabled = optional(bool, null)

    # "The ARN for the KMS key to encrypt Performance Insights data"
    performance_insights_kms_key_id = optional(string, null)

    # "Amount of time in days to retain Performance Insights data. Either 7 (7 days) or 731 (2 years)"
    performance_insights_retention_period = optional(number, null)

    # "Determines whether instances are publicly accessible. Default false"
    publicly_accessible = optional(bool, null)

    # "Create, update, and delete timeout configurations for the cluster instance(s)"
    instance_timeouts = optional(map(string), {})

    # "Map of additional cluster endpoints and their attributes to be created"
    endpoints = optional(any, {})

    # "Map of IAM roles and supported feature names to associate with the cluster"
    iam_roles = optional(map(map(string)), {})

    # "Determines whether to create the IAM role for RDS enhanced monitoring"
    create_monitoring_role = optional(bool, true)

    # "IAM role used by RDS to send enhanced monitoring metrics to CloudWatch"
    monitoring_role_arn = optional(string, "")

    # "Friendly name of the monitoring role"
    iam_role_name = optional(string, null)

    # "Determines whether to use `iam_role_name` as is or create a unique name beginning with the `iam_role_name` as the prefix"
    iam_role_use_name_prefix = optional(bool, false)

    # "Description of the monitoring role"
    iam_role_description = optional(string, null)

    # "Path for the monitoring role"
    iam_role_path = optional(string, null)

    # "Set of exclusive IAM managed policy ARNs to attach to the monitoring role"
    iam_role_managed_policy_arns = optional(list(string), null)

    # "The ARN of the policy that is used to set the permissions boundary for the monitoring role"
    iam_role_permissions_boundary = optional(string, null)

    # "Whether to force detaching any policies the monitoring role has before destroying it"
    iam_role_force_detach_policies = optional(bool, null)

    # "Maximum session duration (in seconds) that you want to set for the monitoring role"
    iam_role_max_session_duration = optional(number, null)

    # "Determines whether autoscaling of the cluster read replicas is enabled"
    autoscaling_enabled = optional(bool, false)

    # "Maximum number of read replicas permitted when autoscaling is enabled"
    autoscaling_max_capacity = optional(number, 2)

    # "Minimum number of read replicas permitted when autoscaling is enabled"
    autoscaling_min_capacity = optional(number, 0)

    # "Autoscaling policy name"
    autoscaling_policy_name = optional(string, "target-metric")

    # "The metric type to scale on. Valid values are `RDSReaderAverageCPUUtilization` and `RDSReaderAverageDatabaseConnections`"
    predefined_metric_type = optional(string, "RDSReaderAverageCPUUtilization")

    # "Cooldown in seconds before allowing further scaling operations after a scale in"
    autoscaling_scale_in_cooldown = optional(number, 300)

    # "Cooldown in seconds before allowing further scaling operations after a scale out"
    autoscaling_scale_out_cooldown = optional(number, 300)

    # "CPU threshold which will initiate autoscaling"
    autoscaling_target_cpu = optional(number, 70)

    # "Average number of connections threshold which will initiate autoscaling. Default value is 70% of db.r4/r5/r6g.large's default max_connections"
    autoscaling_target_connections = optional(number, 700)

    # "Determines whether to create security group for RDS cluster"
    create_security_group = optional(bool, true)

    # "Determines whether the security group name (`name`) is used as a prefix"
    security_group_use_name_prefix = optional(bool, true)

    # "The description of the security group. If value is set to empty string it will contain cluster name in the description"
    security_group_description = optional(string, null)

    # "ID of the VPC where to create security group"
    vpc_id = optional(string, "")

    # "A list of Security Group ID's to allow access to"
    allowed_security_groups = optional(list(string), [])

    # "A list of CIDR blocks which are allowed to access the database"
    allowed_cidr_blocks = optional(list(string), [])

    # "A map of security group egress rule definitions to add to the security group created"
    security_group_egress_rules = optional(map(any), {})

    # "Additional tags for the security group"
    security_group_tags = optional(map(string), {})

    # "Determines whether a cluster parameter should be created or use existing"
    create_db_cluster_parameter_group = optional(bool, false)

    # "The name of the DB cluster parameter group"
    db_cluster_parameter_group_name = optional(string, null)

    # "Determines whether the DB cluster parameter group name is used as a prefix"
    db_cluster_parameter_group_use_name_prefix = optional(bool, true)

    # "The description of the DB cluster parameter group. Defaults to \"Managed by Terraform\""
    db_cluster_parameter_group_description = optional(string, null)

    # "The family of the DB cluster parameter group"
    db_cluster_parameter_group_family = optional(string, "")

    # "A list of DB cluster parameters to apply. Note that parameters may differ from a family to an other"
    db_cluster_parameter_group_parameters = optional(list(map(string)), [])

    # "Determines whether a DB parameter should be created or use existing"
    create_db_parameter_group = optional(bool, false)

    # "Determines whether the DB parameter group name is used as a prefix"
    db_parameter_group_use_name_prefix = optional(bool, true)

    # "The description of the DB parameter group. Defaults to \"Managed by Terraform\""
    db_parameter_group_description = optional(string, null)

    # "The family of the DB parameter group"
    db_parameter_group_family = optional(string, "")

    # "A list of DB parameters to apply. Note that parameters may differ from a family to an other"
    db_parameter_group_parameters = optional(list(map(string)), [])

    # "Do you agree that Putin doesn't respect Ukrainian sovereignty and territorial integrity? More info: https://en.wikipedia.org/wiki/Putin_khuylo!"
    putin_khuylo = optional(bool, true)

  })
}
