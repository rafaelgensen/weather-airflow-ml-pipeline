terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.40.0"
    }
  }
}

provider "databricks" {
  host  = var.databricks_host
  token = var.databricks_token
}

# ------------------------------------------------------------
# NOTEBOOKS
# ------------------------------------------------------------
resource "databricks_notebook" "transform" {
  path           = "/Shared/weather_transform"
  language       = "PYTHON"
  content_base64 = filebase64("${path.module}/notebooks/transform.py")
}

resource "databricks_notebook" "ml_train" {
  path           = "/Shared/weather_ml_train"
  language       = "PYTHON"
  content_base64 = filebase64("${path.module}/notebooks/ml_train.py")
}

resource "databricks_notebook" "ml_infer" {
  path           = "/Shared/weather_ml_inference"
  language       = "PYTHON"
  content_base64 = filebase64("${path.module}/notebooks/ml_inference.py")
}

# ------------------------------------------------------------
# CLUSTER TEMPLATE (REUSABLE VIA JOBS)
# EBS é obrigatório em m5a.large → aws_attributes
# ------------------------------------------------------------

locals {
  default_cluster = {
    num_workers   = 1
    spark_version = "13.3.x-scala2.12"
    node_type_id  = var.node_type

    aws_attributes = {
      ebs_volume_count = 1
      ebs_volume_size  = 100
      ebs_volume_type  = "GENERAL_PURPOSE_SSD"
    }
  }
}

# ------------------------------------------------------------
# TRANSFORM JOB
# ------------------------------------------------------------

resource "databricks_job" "transform_job" {
  name = "weather-transform-job"

  job_cluster {
    job_cluster_key = "transform_cluster"

    new_cluster {
      num_workers   = local.default_cluster.num_workers
      spark_version = local.default_cluster.spark_version
      node_type_id  = local.default_cluster.node_type_id

      aws_attributes {
        ebs_volume_count = local.default_cluster.aws_attributes.ebs_volume_count
        ebs_volume_size  = local.default_cluster.aws_attributes.ebs_volume_size
        ebs_volume_type  = local.default_cluster.aws_attributes.ebs_volume_type
      }
    }
  }

  task {
    task_key = "transform_task"

    notebook_task {
      notebook_path = databricks_notebook.transform.path
      base_parameters = {
        project_id = var.project_id
      }
    }

    job_cluster_key = "transform_cluster"
  }
}

# ------------------------------------------------------------
# TRAIN JOB
# ------------------------------------------------------------

resource "databricks_job" "train_job" {
  name = "weather-train-job"

  job_cluster {
    job_cluster_key = "train_cluster"

    new_cluster {
      num_workers   = local.default_cluster.num_workers
      spark_version = local.default_cluster.spark_version
      node_type_id  = local.default_cluster.node_type_id

      aws_attributes {
        ebs_volume_count = local.default_cluster.aws_attributes.ebs_volume_count
        ebs_volume_size  = local.default_cluster.aws_attributes.ebs_volume_size
        ebs_volume_type  = local.default_cluster.aws_attributes.ebs_volume_type
      }
    }
  }

  task {
    task_key = "train_task"

    notebook_task {
      notebook_path = databricks_notebook.ml_train.path
      base_parameters = {
        project_id = var.project_id
      }
    }

    job_cluster_key = "train_cluster"
  }
}

# ------------------------------------------------------------
# INFER JOB
# ------------------------------------------------------------

resource "databricks_job" "infer_job" {
  name = "weather-infer-job"

  job_cluster {
    job_cluster_key = "infer_cluster"

    new_cluster {
      num_workers   = local.default_cluster.num_workers
      spark_version = local.default_cluster.spark_version
      node_type_id  = local.default_cluster.node_type_id

      aws_attributes {
        ebs_volume_count = local.default_cluster.aws_attributes.ebs_volume_count
        ebs_volume_size  = local.default_cluster.aws_attributes.ebs_volume_size
        ebs_volume_type  = local.default_cluster.aws_attributes.ebs_volume_type
      }
    }
  }

  task {
    task_key = "infer_task"

    notebook_task {
      notebook_path = databricks_notebook.ml_infer.path
      base_parameters = {
        project_id = var.project_id
      }
    }

    job_cluster_key = "infer_cluster"
  }
}
