# ============================================================
# eks.tf - EKS cluster (control plane only, no managed nodes)
# Module: terraform-aws-modules/eks/aws  ~> 21.0
# ============================================================
# KodeKloud SCP constraints addressed:
#   1. iam:PassRole only works for "eksClusterRole" / "eksNodeRole"
#      -> create_iam_role = false, point to pre-created eksClusterRole
#   2. iam:TagPolicy blocked -> encryption_config = null, create_kms_key = false
#   3. eks:CreateNodegroup blocked unconditionally
#      -> eks_managed_node_groups removed; use self-managed nodes (Phase 3)
#   4. logs:DeleteLogGroup blocked -> create_cloudwatch_log_group = false
#      (EKS creates the log group itself; Terraform just won't manage it)
# ============================================================

# Additional security group: allow bastion to reach EKS API (port 443)
resource "aws_security_group" "eks_additional" {
  name        = "${var.project_name}-eks-additional-sg"
  description = "Allow bastion host to reach EKS API on port 443"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "HTTPS from bastion host"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-eks-additional-sg"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "${var.project_name}-eks"
  kubernetes_version = var.kubernetes_version

  # ---------- IAM Role ----------
  # The module's auto-generated role name triggers iam:PassRole denial.
  # KodeKloud SCP only whitelists "eksClusterRole" exactly.
  create_iam_role = false
  iam_role_arn    = aws_iam_role.eks_cluster_role.arn

  # ---------- Encryption ----------
  # Setting to null makes enable_encryption_config = false inside the module,
  # which skips the entire encryption_config block on aws_eks_cluster.
  # This avoids both the missing key_arn error and the iam:TagPolicy denial.
  encryption_config        = null
  create_kms_key           = false
  attach_encryption_policy = false

  # ---------- CloudWatch ----------
  # logs:DeleteLogGroup is blocked by the SCP. If Terraform manages the
  # log group, terraform destroy will fail. Letting EKS create its own
  # log group (unmanaged by Terraform) avoids the problem entirely.
  create_cloudwatch_log_group = false

  # ---------- Auth ----------
  # API_AND_CONFIG_MAP keeps both node-join paths available.
  authentication_mode = "API_AND_CONFIG_MAP"

  # Grants the Terraform caller (lab user) cluster-admin automatically
  enable_cluster_creator_admin_permissions = true

  # ---------- Network ----------
  # Private API endpoint only; kubectl goes through bastion
  endpoint_public_access  = false
  endpoint_private_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  additional_security_group_ids = [aws_security_group.eks_additional.id]

  # ---------- Addons ----------
  # before_compute = true is irrelevant without managed nodes,
  # but harmless to keep for when self-managed nodes join later.
  addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent    = true
      before_compute = true
    }
    eks-pod-identity-agent = {
      most_recent    = true
      before_compute = true
    }
  }

  # ---------- NO managed node groups ----------
  # eks:CreateNodegroup is blocked unconditionally by the KodeKloud SCP.
  # Worker nodes are provisioned as self-managed (Phase 3 in the runbook)
  # via the AWS CloudFormation EKS node template after terraform apply.

  tags = {
    Name = "${var.project_name}-eks"
  }
}
