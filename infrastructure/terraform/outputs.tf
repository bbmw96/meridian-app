output "eks_cluster_endpoint" {
  description = "Endpoint URL of the EKS cluster API server. Use this to configure kubectl and CI/CD pipelines."
  value       = module.eks.cluster_endpoint
  sensitive   = false
}

output "eks_cluster_name" {
  description = "Name of the provisioned EKS cluster."
  value       = module.eks.cluster_name
}

output "eks_cluster_certificate_authority" {
  description = "Base64-encoded certificate authority data for the EKS cluster."
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "rds_endpoint" {
  description = "Connection endpoint for the MERIDIAN RDS PostgreSQL instance."
  value       = aws_db_instance.meridian.endpoint
  sensitive   = false
}

output "rds_port" {
  description = "Port on which the RDS PostgreSQL instance listens."
  value       = aws_db_instance.meridian.port
}

output "redis_endpoint" {
  description = "Primary endpoint for the ElastiCache Redis replication group."
  value       = aws_elasticache_replication_group.meridian.primary_endpoint_address
  sensitive   = false
}

output "redis_reader_endpoint" {
  description = "Reader endpoint for the ElastiCache Redis replication group. Use for read-heavy workloads."
  value       = aws_elasticache_replication_group.meridian.reader_endpoint_address
  sensitive   = false
}

output "ecr_urls" {
  description = "Map of service names to their ECR repository URLs. Use these in CI/CD pipelines to push and pull images."
  value = {
    for service, repo in aws_ecr_repository.services :
    service => repo.repository_url
  }
}

output "ml_artefacts_bucket" {
  description = "Name of the S3 bucket used for storing ML model artefacts."
  value       = aws_s3_bucket.ml_artefacts.bucket
}

output "vpc_id" {
  description = "ID of the MERIDIAN VPC."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets where application workloads run."
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "IDs of the public subnets used for load balancers and NAT gateways."
  value       = module.vpc.public_subnets
}
