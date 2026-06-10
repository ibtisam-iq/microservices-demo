# ============================================================
# outputs.tf — values printed after terraform apply
# ============================================================

# ---- VPC ---------------------------------------------------

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "Primary CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "IDs of the private (EKS node) subnets"
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "IDs of the public (NAT-GW + bastion) subnets"
  value       = module.vpc.public_subnets
}

# ---- EKS ---------------------------------------------------

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "HTTPS endpoint of the EKS API server (private)"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded CA certificate — used in kubeconfig"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL — needed for IRSA (IAM Roles for Service Accounts)"
  value       = module.eks.cluster_oidc_issuer_url
}

output "kubeconfig_command" {
  description = "Run this command on the bastion host to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${data.aws_region.current.region} --name ${module.eks.cluster_name}"
}

# ---- Bastion -----------------------------------------------

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = module.bastion.public_ip
}

output "bastion_ssh_command" {
  description = "SSH command to connect to the bastion host"
  value       = "ssh -i ${var.bastion_key_name}.pem ubuntu@${module.bastion.public_ip}"
}

output "bastion_ami_id" {
  description = "Ubuntu 26.04 AMI ID used for the bastion host"
  value       = data.aws_ami.ubuntu_2604.id
}

# ---- Account / Region --------------------------------------

output "aws_account_id" {
  description = "AWS account ID resources were deployed into"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS region resources were deployed into"
  value       = data.aws_region.current.region
}
