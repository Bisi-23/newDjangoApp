# Define the provider
# Define the provider
provider "aws" {
  alias  = "second"
  region = "us-east-1"
}

# Define S3 bucket
resource "aws_s3_bucket" "mongodb_bucket" {
  provider = aws.second
  bucket   = "bisco0140"
}

# Enable versioning for S3 bucket
resource "aws_s3_bucket_versioning" "mongodb_bucket_versioning" {
  bucket = aws_s3_bucket.mongodb_bucket.bucket

  versioning_configuration {
    status = "Enabled"
  }
}

# Define IAM role
resource "aws_iam_role" "mongodb_role" {
  provider = aws.second
  name     = "mongodb_admin_role"
  
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }]
  })
}

# Attach policies to IAM role
resource "aws_iam_role_policy_attachment" "mongodb_admin_s3_attachment" {
  role       = aws_iam_role.mongodb_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Define MongoDB instance
resource "aws_instance" "mongodb" {
  ami           = "ami-0c7217cdde317cfec"
  instance_type = "t2.micro"
  key_name      = "public-kp"
  subnet_id     = module.myapp-vpc.private_subnets[0]  # Assuming private subnet is used for the instance

  // Associate the instance with the security group
  vpc_security_group_ids = [aws_security_group.myapp_security_group.id]

  // Allocate a public IP address to the instance
  associate_public_ip_address = true
    tags = {
    Name = "mongodb_server"
  }
}

# Declare the data source for AWS security groups
data "aws_security_groups" "vpc_security_groups" {
  // No need to specify vpc_ids here
}

# Define security group rules
resource "aws_security_group_rule" "tcp_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535  # Allow all TCP traffic
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]  # Allow access from any source
  security_group_id = data.aws_security_groups.vpc_security_groups.ids[0]  # Assuming only one security group is associated with the VPC
}

resource "aws_security_group_rule" "ssh_ingress" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]  # Allow SSH access from any source
  security_group_id = data.aws_security_groups.vpc_security_groups.ids[0]  # Assuming only one security group is associated with the VPC
}

resource "aws_security_group_rule" "http_ingress" {
  type              = "ingress"
  description       = "HTTP"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_groups.vpc_security_groups.ids[0]
}

resource "aws_security_group_rule" "https_ingress" {
  type              = "ingress"
  description       = "HTTPS"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_groups.vpc_security_groups.ids[0]
}

resource "aws_security_group_rule" "custom_ingress" {
  type              = "ingress"
  description       = "Custom TCP Port 8080"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_groups.vpc_security_groups.ids[0]
}

# Define ECR repository
resource "aws_ecr_repository" "mongodb_repository" {
  name = "mongodb_repository"
}

# Define outputs
output "mongodb_server_public_ip" {
  value = aws_instance.mongodb.public_ip
}

output "bucket_name" {
  value = aws_s3_bucket.mongodb_bucket.bucket
}
