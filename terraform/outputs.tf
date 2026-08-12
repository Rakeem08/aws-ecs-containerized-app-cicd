output "vpc_id" {
  description = "ID of the project VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "frontend_ecr_url" {
  description = "Frontend ECR repository URL"
  value       = aws_ecr_repository.frontend.repository_url
}

output "backend_ecr_url" {
  description = "Backend ECR repository URL"
  value       = aws_ecr_repository.backend.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "frontend_service_name" {
  description = "Frontend ECS service name"
  value       = aws_ecs_service.frontend.name
}

output "backend_service_name" {
  description = "Backend ECS service name"
  value       = aws_ecs_service.backend.name
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS address"
  value       = aws_lb.main.dns_name
}

output "application_url" {
  description = "Public frontend URL"
  value       = "http://${aws_lb.main.dns_name}"
}

output "backend_url" {
  description = "Public backend API URL"
  value       = "http://${aws_lb.main.dns_name}/api"
}

output "jenkins_public_ip" {
  description = "Jenkins Elastic IP address"
  value       = aws_eip.jenkins.public_ip
}

output "jenkins_url" {
  description = "Public Jenkins URL"
  value       = "http://${aws_eip.jenkins.public_ip}:8080"
}