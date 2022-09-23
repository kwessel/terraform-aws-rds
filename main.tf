locals {
  final_snapshot_identifier = var.final_snapshot_identifier != "" ? var.final_snapshot_identifier : format("%s-FINAL", var.identifier)
  security_group_names      = compact(split(" ", var.security_group_names))

  # TODO: Rethink how to make restoring from snapshot and dumping
  # to snapshot more foolproof.
  # snapshot_identifier = "${var.snapshot_identifier != "" ? var.snapshot_identifier : format("%s", var.identifier)}"
}

data "aws_security_group" "selected" {
  count = length(local.security_group_names)
  name  = local.security_group_names[count.index]
}

resource "random_password" "default" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_instance" "default" {
  allocated_storage                   = var.allocated_storage
  max_allocated_storage               = var.max_allocated_storage
  allow_major_version_upgrade         = var.allow_major_version_upgrade
  apply_immediately                   = var.apply_immediately
  auto_minor_version_upgrade          = var.auto_minor_version_upgrade
  availability_zone                   = var.availability_zone
  backup_retention_period             = var.backup_retention_period
  backup_window                       = var.backup_window
  character_set_name                  = var.character_set_name
  copy_tags_to_snapshot               = var.copy_tags_to_snapshot
  db_subnet_group_name                = var.db_subnet_group_name
  deletion_protection                 = var.deletion_protection
  enabled_cloudwatch_logs_exports     = var.enabled_cloudwatch_logs_exports
  engine                              = var.engine
  engine_version                      = var.engine_version
  final_snapshot_identifier           = local.final_snapshot_identifier
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  identifier                          = var.identifier
  instance_class                      = var.instance_class
  iops                                = var.iops
  kms_key_id                          = var.kms_key_id
  license_model                       = var.license_model
  maintenance_window                  = var.maintenance_window
  # monitoring_interval                 = var.monitoring_interval
  # monitoring_role_arn                 = coalesce(var.monitoring_role_arn, join("", aws_iam_role.enhanced_monitoring.*.arn))
  multi_az             = var.multi_az
  db_name              = var.db_name
  option_group_name    = var.option_group_name
  parameter_group_name = var.parameter_group_name
  password             = random_password.default.result
  port                 = var.port
  publicly_accessible  = var.publicly_accessible
  replicate_source_db  = var.replicate_source_db
  skip_final_snapshot  = var.skip_final_snapshot
  snapshot_identifier  = var.snapshot_identifier
  storage_encrypted    = var.storage_encrypted
  storage_type         = var.storage_type
  tags                 = merge({ "Name" = var.identifier }, var.tags)
  timeouts {
    create = lookup(var.timeouts, "create", null)
    delete = lookup(var.timeouts, "delete", null)
    update = lookup(var.timeouts, "update", null)
  }
  username = var.username

  # Password is automatically generated and should be IMMEDIATELY reset
  # via the AWS console or CLI. We therefore ignore password changes
  # after the instance is created. We also ignore database engine versions
  # in the configuration file after automatic minor version upgrades have
  # occurred.

  lifecycle {
    ignore_changes = [
      engine_version,
      password,
    ]
    prevent_destroy = true
  }

  # Calculated from "security_group_names" variable
  vpc_security_group_ids = data.aws_security_group.selected.*.id
}
