include {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../../..//infrastructure-modules/eks/"
}

locals {
  common_vars  = merge(yamldecode(file("${get_terragrunt_dir()}/../common.yaml")), try(yamldecode(file(replace("${get_terragrunt_dir()}/../common.yaml", "/\\.yaml$/", ".local.yaml"))), {}))
  deploy_vars  = merge(yamldecode(file("${get_terragrunt_dir()}/../deploy.yaml")), try(yamldecode(file(replace("${get_terragrunt_dir()}/../deploy.yaml", "/\\.yaml$/", ".local.yaml"))), {}))
  cluster_name = "netbird"
  common_tags = {
    Env : "dev",
    Owner : "systemengg",
    Pod : "DevOps"
    Project : "netbird",
  }
  worker_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" : "owned"
    "kubernetes.io/role/elb" : 1
  }
  alias = "eks"
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id             = "vpc-mock1234567890"
    public_subnet_ids  = ["subnet-mock1", "subnet-mock2", "subnet-mock3"]
    private_subnet_ids = ["subnet-mock4", "subnet-mock5", "subnet-mock6"]
  }
}

inputs = {
  region                           = local.common_vars["aws_region"]
  cluster_name                     = local.cluster_name
  eks_cluster_version              = "1.36"
  vpc_id                           = dependency.vpc.outputs.vpc_id
  subnets                          = concat(dependency.vpc.outputs.private_subnet_ids, dependency.vpc.outputs.public_subnet_ids)
  tags                             = local.common_tags
  endpoint_private                 = true
  endpoint_public                  = true
  enabled_cluster_log_types        = []
  key_name                         = "netbird-eks"
  alias                            = "netbird-eks"
  userdatafile                     = true
  max_unavailable_percentage_nodes = 10
  enable_audit_eks_ami             = false
  enable_bottlerocket_ami          = false
  manage_aws_auth                  = false
  authentication_mode              = "API"

  cluster_security_group_additional_rules = {
    ingress_cluster_443_from_vpn = {
      description              = "Allow access to cluster API from netbird vpn client"
      protocol                 = "tcp"
      port                     = 443
      type                     = "ingress"
      source_security_group_id = null
      cidr_blocks              = ["111.235.64.134/32"]
    }
  }

  worker_security_group_additional_rules = {
    ingress_worker_udp_3478 = {
      from_port                = 3478
      to_port                  = 3478
      description              = "Allow NetBird UDP 3478 NodePort access"
      type                     = "ingress"
      protocol                 = "udp"
      source_security_group_id = null
      self                     = null
      cidr_blocks              = ["0.0.0.0/0"]
      ipv6_cidr_blocks         = null
    }
  }

  bootstrap_admin_role_arn = "arn:aws:iam::${local.common_vars.aws_account_id}:role/aws-reserved/sso.amazonaws.com/${local.deploy_vars.sso_admin_role_name}"

  map_roles = [
    {
      rolearn  = "arn:aws:iam::${local.common_vars.aws_account_id}:role/eks-${local.cluster_name}-nodegroup-role"
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:nodes", "system:bootstrappers"]
    }
  ]

  map_users = []

  access_entries = [
    {
      principal_arn = "arn:aws:iam::${local.common_vars.aws_account_id}:role/${local.deploy_vars.cicd_role_name}"
      type          = "STANDARD"
      policy_key    = "cluster_admin"
      scope_type    = "cluster"
    },
    {
      principal_arn = "arn:aws:iam::${local.common_vars.aws_account_id}:role/eks-${local.cluster_name}-nodegroup-role"
      type          = "EC2_LINUX"
      policy_key    = "view"
      scope_type    = "cluster"
    }
  ]

  cluster_addons = {
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
      addon_version     = "v1.20.1-eksbuild.3"
      preserve          = true
    }
    aws-ebs-csi-driver = {
      resolve_conflicts        = "OVERWRITE"
      addon_version            = "v1.66.0-eksbuild.1"
      service_account_role_arn = "arn:aws:iam::${local.common_vars.aws_account_id}:role/eks-${local.cluster_name}-nodegroup-role"
    }
    coredns = {
      resolve_conflicts = "OVERWRITE"
      addon_version     = "v1.14.6-eksbuild.4"
      preserve          = true
    }
    kube-proxy = {
      resolve_conflicts = "OVERWRITE"
      addon_version     = "v1.35.3-eksbuild.2"
    }
    kube-state-metrics = {
      resolve_conflicts        = "OVERWRITE"
      addon_version            = "v2.20.0-eksbuild.6"
      service_account_role_arn = "arn:aws:iam::${local.common_vars.aws_account_id}:role/eks-${local.cluster_name}-nodegroup-role"
    }
    metrics-server = {
      resolve_conflicts = "OVERWRITE"
      addon_version     = "v0.9.0-eksbuild.11"
    }
  }

  ### Node Group
  create_node_group = true
  node_groups = {
    "netbird" = {
      subnets          = dependency.vpc.outputs.private_subnet_ids
      instance_type    = ["t3.large"]
      desired_capacity = 3
      max_capacity     = 4
      min_capacity     = 2
      capacity_type    = "ON_DEMAND"
      tags             = merge(local.common_tags, local.worker_tags)
      kubeargs         = "--node-labels=workload=netbird,lifecycle=normal,managed=false --kube-reserved cpu=100m,memory=0.1Gi,ephemeral-storage=1Gi --system-reserved cpu=100m,memory=0.1Gi,ephemeral-storage=1Gi --eviction-hard memory.available<200Mi,nodefs.available<10% --cpu-cfs-quota=false"
      volume_size      = 30
      audit_ami        = false
      bottlerocket_ami = false
    }
  }
}
