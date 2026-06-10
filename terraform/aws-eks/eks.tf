# ============================================================
# eks.tf - EKS cluster + managed node group
# Module: terraform-aws-modules/eks/aws  v21.23.0
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

  # API_AND_CONFIG_MAP: both the Access Entry API and the legacy
  # aws-auth ConfigMap remain active simultaneously.
  authentication_mode = "API_AND_CONFIG_MAP"

  # Grants the Terraform IAM identity cluster-admin automatically
  enable_cluster_creator_admin_permissions = true

  # Private API endpoint - kubectl traffic goes through bastion
  endpoint_public_access  = false
  endpoint_private_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  additional_security_group_ids = [aws_security_group.eks_additional.id]

  # before_compute = true ensures vpc-cni and pod-identity-agent
  # are installed before any worker nodes join.
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

  eks_managed_node_groups = {
    general = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      node_repair_config = {
        enabled = true
      }

      update_config = {
        max_unavailable_percentage = 33
      }

      labels = {
        role = "general"
      }

      tags = {
        Name = "${var.project_name}-eks-node"
      }
    }
  }

  tags = {
    Name = "${var.project_name}-eks"
  }
}
