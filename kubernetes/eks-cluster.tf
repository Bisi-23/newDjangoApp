# Define AWS provider settings for the EKS service
# Define AWS provider settings for the EKS service
provider "aws" {
  alias = "third"
  region = "us-east-1"  # Set the region for the EKS cluster
  assume_role {
    role_arn = "arn:aws:iam::548924361033:role/your-terraform-role"  # Assume a role for Terraform operations
  }
  allowed_account_ids = ["548924361033"]  # Specify allowed AWS account IDs
  allowed_regions     = ["us-east-1"]     # Specify allowed AWS regions
}

# Provision an EKS cluster using the terraform-aws-modules/eks/aws module
module "eks_cluster" {
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
  alias                  = "eks"
  host                   = module.eks_cluster.cluster_endpoint
  token                  = module.eks_cluster.cluster_token
  cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate_authority)
}
