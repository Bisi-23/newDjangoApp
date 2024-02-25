# Define AWS provider settings for the EKS service
provider "aws" {
  alias = "third"
  region = "us-east-1"  # Set the region for the EKS cluster
  endpoints = {
    eks = "eks.us-east-1.amazonaws.com"  # Specify the EKS endpoint
  }
  assume_role {
    role_arn = "arn:aws:iam::548924361033:role/your-terraform-role"  # Assume a role for Terraform operations
  }
  allowed_account_ids = ["548924361033"]  # Specify allowed AWS account IDs
  allowed_regions     = ["us-east-1"]     # Specify allowed AWS regions
  allowed_dns_servers = var.custom_dns_servers  # Specify custom DNS servers if needed
}

# Provision an EKS cluster using the terraform-aws-modules/eks/aws module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.21.0"

  cluster_name    = "myapp-eks-cluster"  # Name of the EKS cluster
  cluster_version = "1.27"               # Version of Kubernetes to use

  subnet_ids = module.myapp-vpc.private_subnets  # Subnets for the EKS cluster
  vpc_id     = module.myapp-vpc.vpc_id           # VPC ID for the EKS cluster

  tags = {
    environment = "development"
    application = "myapp"
  }

  # Define managed node groups for the EKS cluster
  eks_managed_node_groups = {
    dev = {
      min_size       = 1
      max_size       = 3
      desired_size   = 3
      instance_types = ["t2.small"]
      key_name       = "public-kp"
    }
  }
}

# Define Kubernetes provider settings to interact with the EKS cluster
provider "kubernetes" {
  host                    = data.aws_eks_cluster.myapp-cluster.endpoint
  token                   = data.aws_eks_cluster_auth.myapp-cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.myapp-cluster.certificate_authority.0.data)
}

# Fetch data about the EKS cluster using data sources
data "aws_eks_cluster" "myapp-cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "myapp-cluster" {
  name = module.eks.cluster_id
}

