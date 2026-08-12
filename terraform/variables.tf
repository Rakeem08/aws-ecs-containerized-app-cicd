variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name used when labeling AWS resources"
  type        = string
  default     = "rakeem-devops"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "IP range for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "key_name" {
  description = "Existing AWS EC2 key pair"
  type        = string
  default     = "rakeem"
}

variable "ssh_allowed_cidr" {
  description = "Public IP address allowed to SSH into Jenkins"
  type        = string
}

variable "frontend_port" {
  description = "Frontend container port"
  type        = number
  default     = 3000
}

variable "backend_port" {
  description = "Backend container port"
  type        = number
  default     = 8080
}

variable "task_cpu" {
  description = "CPU units for each Fargate task"
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Memory in MB for each Fargate task"
  type        = number
  default     = 1024
}

variable "min_tasks" {
  description = "Minimum number of tasks"
  type        = number
  default     = 1
}

variable "desired_tasks" {
  description = "Normal number of running tasks"
  type        = number
  default     = 1
}

variable "max_tasks" {
  description = "Maximum number of tasks"
  type        = number
  default     = 4
}

variable "cpu_target" {
  description = "CPU percentage that triggers scaling"
  type        = number
  default     = 50
}

variable "jenkins_instance_type" {
  description = "EC2 size for the Jenkins server"
  type        = string
  default     = "t3.small"
}