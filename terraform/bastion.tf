# ============================================================
# bastion.tf — bastion host, SSH key pair, security group
# Module: terraform-aws-modules/ec2-instance/aws  v6.4.0
# ============================================================
# Improvements over instructor baseline:
#  • Ubuntu 26.04 (Noble) AMI via data.tf filter using Canonical
#    owner 099720109477 with hvm-ssd-gp3/ubuntu-resolute-26.04 pattern
#    (matches your exact aws ec2 describe-images command)
#  • Key name from variable — not hardcoded
#  • IMDSv2 enforced (http_tokens = required) — security hardening
#  • Metadata hop limit = 2 (needed if kubectl runs inside a container
#    on the bastion itself)
#  • EBS root volume encrypted at rest
#  • Instance name from var.project_name
# ============================================================

# ---- SSH key pair ------------------------------------------

resource "tls_private_key" "bastion" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion" {
  key_name   = var.bastion_key_name
  public_key = tls_private_key.bastion.public_key_openssh

  tags = {
    Name = var.bastion_key_name
  }
}

# Save private key locally so you can SSH in after apply
resource "local_file" "bastion_private_key" {
  content         = tls_private_key.bastion.private_key_pem
  filename        = "${path.module}/${var.bastion_key_name}.pem"
  file_permission = "0400"
}

# ---- Security group ----------------------------------------

resource "aws_security_group" "bastion_sg" {
  name        = "${var.project_name}-bastion-sg"
  description = "Allow SSH from operator IP only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH from operator's current public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"]
  }

  egress {
    description = "Allow all outbound (kubectl, apt, etc.)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-bastion-sg"
  }
}

# ---- Bastion EC2 instance ----------------------------------

module "bastion" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "6.4.0"

  name          = "${var.project_name}-bastion"
  ami           = data.aws_ami.ubuntu_2604.id
  instance_type = var.bastion_instance_type
  key_name      = aws_key_pair.bastion.key_name

  # Place in the first public subnet
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true

  # Detailed CloudWatch monitoring
  monitoring = true

  # IMDSv2 required — prevents SSRF-based metadata attacks
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"   # IMDSv2
    http_put_response_hop_limit = 2            # needed if kubectl runs in a container on bastion
  }

  # Encrypted root volume
  root_block_device = {
    encrypted   = true
    volume_type = "gp3"
    size        = 20
  }

  tags = {
    Name = "${var.project_name}-bastion"
    Role = "bastion"
  }
}
