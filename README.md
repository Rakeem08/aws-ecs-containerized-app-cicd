# AWS ECS Fargate — Containerized Application and Jenkins CI/CD

Deployment of a React frontend and Express backend to AWS ECS Fargate using Docker, Terraform, Jenkins, ECR, an Application Load Balancer, and ECS Service Auto Scaling.

## Project at a glance

**Business scenario:** A two-tier web application needs repeatable releases, reliable routing, and room to handle traffic increases without manually managing servers.

**What I built:** Containerized a React frontend and Express API using Docker, published the images to Amazon ECR, and deployed both services on ECS Fargate behind an Application Load Balancer. Terraform defines the AWS infrastructure; Jenkins automates the build-and-deploy workflow.

**Implemented capabilities**

- Terraform defines two private-subnet ECS Fargate services behind an ALB, with CPU-based service autoscaling.
- Jenkins builds and publishes frontend/backend images, forces new ECS deployments, and waits for service stability.
- A k6 script ramps traffic to 200 virtual users and checks HTTP responses from `/` and `/api`.

These describe committed configuration. Runtime throughput and scaling outcomes require captured test results; they are not established by the script alone.

**Key decisions:** Fargate reduces server administration; the ALB provides path-based routing and health checks; Terraform makes environments reproducible; Jenkins reduces repetitive release steps.

**Production improvements to prioritize:** HTTPS with ACM and a domain, image digest pinning, stronger release rollback controls, and actionable service-level alerts.

**Stack:** AWS ECS Fargate · ECR · ALB · CloudWatch · Terraform · Docker · Jenkins · React · Express

**Explore:** [Architecture](#architecture) · [Infrastructure](#aws-infrastructure) · [Source code](https://github.com/Rakeem08/aws-ecs-containerized-app-cicd)

> **Portfolio environment:** Deployment addresses below document the original lab. They are not guaranteed to be active endpoints.

## Historical Lab URLs

- Frontend: http://rakeem-devops-alb-38784143.us-east-1.elb.amazonaws.com
- Backend API: http://rakeem-devops-alb-38784143.us-east-1.elb.amazonaws.com/api
- Jenkins: http://3.215.173.240:8080

These addresses are historical references. Retrieve current addresses from your own Terraform outputs after deployment.

## Architecture

![AWS ECS Fargate delivery and application runtime](docs/images/ecs-architecture.svg)

[Open the full-size architecture graphic](docs/images/ecs-architecture.svg)

The public ALB routes the default path to the React service and `/api` to the Express service. Both Fargate services run in private subnets. Jenkins builds and pushes the images, forces new service deployments, and waits for stability. Dotted arrows show deployment, image, or telemetry flow. The current task definitions use `:latest`; the pipeline also publishes build-number tags.

## AWS Infrastructure

Terraform provisions:

- One VPC
- Two public subnets
- Two private subnets
- Internet Gateway
- NAT Gateway
- Public Application Load Balancer
- Frontend and backend target groups
- ECS cluster running with Fargate
- Frontend and backend ECS services
- Frontend and backend ECR repositories
- CloudWatch log groups
- IAM roles and policies
- Security groups
- Jenkins EC2 server with an Elastic IP
- ECS Service Auto Scaling

## ECS Configuration

Each frontend and backend task uses:

- Launch type: Fargate
- CPU: 512 CPU units or 0.5 vCPU
- Memory: 1024 MB or 1 GB
- Minimum tasks: 1
- Desired tasks: 1
- Maximum tasks: 4
- CPU scaling target: 50%

## Repository Structure

```text
.
├── backend/
│   ├── Dockerfile
│   ├── config.js
│   └── index.js
├── frontend/
│   ├── Dockerfile
│   └── src/
├── load-test/
│   └── load-test.js
├── terraform/
│   ├── alb.tf
│   ├── autoscaling.tf
│   ├── ecr.tf
│   ├── ecs.tf
│   ├── iam.tf
│   ├── jenkins.tf
│   ├── network.tf
│   ├── outputs.tf
│   ├── provider.tf
│   ├── security-groups.tf
│   ├── terraform.tfvars.example
│   └── variables.tf
├── Jenkinsfile
└── README.md
```

## Prerequisites

Install the following tools:

- Git
- Node.js 16
- npm
- Docker Desktop
- Terraform
- AWS CLI
- An AWS account with the required permissions
- An existing EC2 key pair

Configure AWS CLI:

```powershell
aws configure
aws sts get-caller-identity
```

## Run the Application Locally

Clone the repository:

```powershell
git clone https://github.com/Rakeem08/aws-ecs-containerized-app-cicd.git
cd aws-ecs-containerized-app-cicd
```

### Backend

```powershell
cd backend
npm ci
npm start
```

The backend will be available at:

```text
http://localhost:8080
```

### Frontend

Open another terminal:

```powershell
cd frontend
npm ci
npm start
```

The frontend will be available at:

```text
http://localhost:3000
```

A successful connection displays `SUCCESS` followed by a GUID.

## Run with Docker

From the repository root, build both images:

```powershell
docker build -t backend-app .\backend
docker build --build-arg REACT_APP_API_URL=http://localhost:8080 -t frontend-app .\frontend
```

Run both containers:

```powershell
docker run -d --name backend -p 8080:8080 backend-app
docker run -d --name frontend -p 3000:3000 frontend-app
```

Verify:

```powershell
docker ps
```

Open:

```text
http://localhost:3000
```

Stop the containers:

```powershell
docker stop frontend backend
docker rm frontend backend
```

## Deploy the Infrastructure with Terraform

Create a private variables file:

```powershell
Copy-Item .\terraform\terraform.tfvars.example .\terraform\terraform.tfvars
```

Update `terraform/terraform.tfvars` with the public IP address permitted to SSH into Jenkins:

```hcl
ssh_allowed_cidr = "YOUR_PUBLIC_IP/32"
```

The real `terraform.tfvars`, Terraform state, saved plans, and private keys are ignored by Git.

Initialize and validate Terraform:

```powershell
terraform -chdir=terraform init
terraform -chdir=terraform fmt -recursive
terraform -chdir=terraform validate
```

### ECR Bootstrap

Create the repositories before starting ECS:

```powershell
terraform -chdir=terraform apply -target="aws_ecr_repository.frontend" -target="aws_ecr_repository.backend" -target="aws_ecr_lifecycle_policy.frontend" -target="aws_ecr_lifecycle_policy.backend"
```

Load the repository addresses:

```powershell
$frontendEcr = terraform -chdir=terraform output -raw frontend_ecr_url
$backendEcr = terraform -chdir=terraform output -raw backend_ecr_url
$registry = ($frontendEcr -split "/")[0]
```

Authenticate Docker with ECR:

```powershell
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $registry
```

Build, tag, and push the initial images:

```powershell
docker build --build-arg REACT_APP_API_URL=/api -t frontend-app .\frontend
docker build -t backend-app .\backend

docker tag frontend-app:latest "${frontendEcr}:latest"
docker tag backend-app:latest "${backendEcr}:latest"

docker push "${frontendEcr}:latest"
docker push "${backendEcr}:latest"
```

Create a fresh Terraform plan and apply it:

```powershell
terraform -chdir=terraform plan -out=tfplan
terraform -chdir=terraform apply "tfplan"
```

Display the deployment outputs:

```powershell
terraform -chdir=terraform output
```

## Jenkins Infrastructure and Setup

Terraform creates an Amazon Linux 2023 EC2 host, an Elastic IP, a security group, and an EC2 IAM instance profile. Its startup script installs Docker, Git, jq, and unzip, starts Docker, and adds `ec2-user` to the Docker group.

**Manual prerequisite:** Terraform does not install Jenkins or build/run a custom Jenkins image. This repository does not include that image's Dockerfile or container launch configuration. Before running the pipeline, install and configure Jenkins on the host or supply your own documented container setup.

The Jenkins execution environment must provide:

- Git, Docker CLI, AWS CLI, and access to a Docker daemon
- AWS access through the EC2 instance role
- Persistent Jenkins storage and the Git/Pipeline plugins
- A Pipeline job using this public repository, branch `*/main`, and script path `Jenkinsfile`

Public HTTPS checkout does not require a GitHub token. If you choose authenticated checkout, keep the read-only token in Jenkins Credentials.

Both SSH and the Jenkins UI on port `8080` are restricted to `ssh_allowed_cidr`. Set it to your administrator IPv4 address followed by `/32`. The pipeline polls GitHub, so it does not need an internet-accessible webhook endpoint.

The EC2 IAM role supports AWS access without storing permanent AWS access keys in Jenkins. Verify the execution environment with `aws sts get-caller-identity` and `docker info` before starting a build.

## Jenkins Pipeline

The `Jenkinsfile` automates:

1. Checking out the public GitHub repository
2. Verifying Docker, AWS CLI, and AWS identity
3. Authenticating with Amazon ECR
4. Building frontend and backend images
5. Tagging images with the Jenkins build number
6. Pushing images to ECR
7. Triggering new ECS service deployments
8. Waiting for both ECS services to become stable

The pipeline configures `pollSCM('H/5 * * * *')` to check for SCM changes approximately every five minutes. Run the job once manually so Jenkins loads its trigger configuration. Select `*/main` in the job's SCM configuration.

The pipeline publishes build-number and `latest` tags, but the committed ECS task definitions use `latest`. Deployment forces a restart using that tag; it does not create task-definition revisions pinned to each build number. Pinning tags or digests and testing rollback remain improvements.

## Load Testing and Auto Scaling

The committed k6 script defines a one-minute ramp to 50 virtual users, five minutes ramping to 200, and a one-minute ramp down to zero. It requests both `/` and `/api` and checks for HTTP 200.

Capture the k6 summary and ECS scaling activity from your own deployment to verify task-count changes. The script alone does not establish a particular iteration count or prove scaling occurred.

Run the test from the repository root:

```powershell
$appUrl = terraform -chdir=terraform output -raw application_url
$loadTestPath = (Resolve-Path .\load-test).Path

docker run --rm `
  -e "BASE_URL=$appUrl" `
  --mount "type=bind,source=$loadTestPath,target=/scripts,readonly" `
  grafana/k6 run /scripts/load-test.js
```

Check the ECS task counts:

```powershell
aws ecs describe-services --cluster rakeem-devops-cluster --services rakeem-devops-frontend-service rakeem-devops-backend-service --region us-east-1 --query "services[].{Service:serviceName,Desired:desiredCount,Running:runningCount,Pending:pendingCount}" --output table
```

Check Auto Scaling activity:

```powershell
aws application-autoscaling describe-scaling-activities --service-namespace ecs --region us-east-1 --max-results 20 --query "ScalingActivities[?contains(ResourceId, 'rakeem-devops')].{Service:ResourceId,Action:Description,Status:StatusCode,Started:StartTime}" --output table
```

## Security

- ECS tasks run in private subnets.
- Only the load balancer can reach the ECS container ports.
- Jenkins uses an IAM role instead of permanent AWS credentials.
- SSH and the Jenkins UI are restricted to the configured administrator CIDR.
- Public repository checkout requires no GitHub token.
- Terraform state, private variable files, and private keys are excluded from Git.
- ECR image scanning is enabled.

## Cleanup

AWS resources in this project create charges. When lab testing is complete, review a destroy plan and remove resources you no longer need:

```powershell
terraform -chdir=terraform plan -destroy -out=destroy.tfplan
terraform -chdir=terraform apply "destroy.tfplan"
```

Preserve any logs or Jenkins data you need before cleanup.

## Author

Rakeem Brewington
