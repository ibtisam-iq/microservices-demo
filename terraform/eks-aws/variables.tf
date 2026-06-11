# ============================================================
# variables.tf — all input variables in one place
# ============================================================

variable "aws_region" {
  description = "AWS region to deploy all resources into"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment label applied to all resources via default_tags"
  type        = string
  default     = "dev"
}

# ---- Naming ------------------------------------------------

variable "project_name" {
  description = "Short project identifier — used as prefix for all resource names"
  type        = string
  default     = "microservices-demo"
}

# ---- VPC ---------------------------------------------------

variable "vpc_cidr" {
  description = "Primary IPv4 CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of Availability Zones. Three AZs gives HA across the node group."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private (EKS node) subnets — one per AZ"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public (NAT-GW + bastion) subnets — one per AZ"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

# ---- EKS ---------------------------------------------------

variable "kubernetes_version" {
  description = "EKS Kubernetes control-plane version"
  type        = string
  default     = "1.35"
}

variable "node_instance_types" {
  description = "EC2 instance type(s) for the managed node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes (for cluster-autoscaler headroom)"
  type        = number
  default     = 6
}

variable "node_desired_size" {
  description = "Desired number of worker nodes at creation time"
  type        = number
  default     = 2
}

# ---- Bastion -----------------------------------------------

variable "bastion_instance_type" {
  description = "EC2 instance type for the bastion host"
  type        = string
  default     = "t3.micro"
}

variable "bastion_key_name" {
  description = "Name given to the AWS Key Pair created for the bastion host"
  type        = string
  default     = "microservices-demo-bastion-key"
}
