📐 Architecture Overview
Infrastructure Architecture
┌─────────────────────────────────────────────────────────┐
│                        AWS Cloud                         │
│                                                         │
│  ┌──────────────────────────────────────────────────┐   │
│  │                  VPC (Multi-AZ)                  │   │
│  │                                                  │   │
│  │  ┌────────────────────────────────────────────┐  │   │
│  │  │           EKS Auto Mode Cluster            │  │   │
│  │  │                                            │  │   │
│  │  │  ┌──────────┐  ┌──────────┐  ┌─────────┐  │  │   │
│  │  │  │ Frontend │  │ Backend  │  │Postgres │  │  │   │
│  │  │  │  (React) │→ │(Node.js) │→ │   DB    │  │  │   │
│  │  │  │ Nginx    │  │ Express  │  │         │  │  │   │
│  │  │  └──────────┘  └──────────┘  └─────────┘  │  │   │
│  │  │                                            │  │   │
│  │  │  ┌──────────────────────────────────────┐  │  │   │
│  │  │  │   AWS Load Balancer (Ingress)        │  │  │   │
│  │  │  └──────────────────────────────────────┘  │  │   │
│  │  └────────────────────────────────────────────┘  │   │
│  │                                                  │   │
│  │  ┌─────────┐  ┌─────────┐  ┌──────────────────┐ │   │
│  │  │   ECR   │  │   S3    │  │  Terraform State  │ │   │
│  │  │(Images) │  │(Logs)   │  │  (Remote Backend) │ │   │
│  │  └─────────┘  └─────────┘  └──────────────────┘ │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
CI Pipeline Flow
  Developer Push / PR
         │
         ▼
  ┌─────────────┐
  │  Checkout   │  GitHub Actions triggered on push to main / PR
  └──────┬──────┘
         │
         ▼
  ┌─────────────┐
  │  Lint &     │  ESLint (frontend) · Node.js test runner (backend)
  │  Unit Test  │  ✗ Fails here → PR blocked, no image built
  └──────┬──────┘
         │
         ▼
  ┌─────────────┐
  │  SAST Scan  │  SonarQube code quality & security analysis
  │  (SonarQube)│  Quality Gate enforced — fails pipeline on violations
  └──────┬──────┘
         │
         ▼
  ┌─────────────┐
  │  Docker     │  Multi-stage Dockerfile build (frontend + backend)
  │  Build      │  Image tagged with git SHA for full traceability
  └──────┬──────┘
         │
         ▼
  ┌─────────────┐
  │  Container  │  Trivy scans image for CVEs (HIGH/CRITICAL = fail)
  │  Scan       │  No unpatched critical vulnerabilities reach ECR
  │  (Trivy)    │
  └──────┬──────┘
         │
         ▼
  ┌─────────────┐
  │  Push to    │  Image pushed to AWS ECR with SHA + latest tags
  │  ECR        │  Only clean images are published
  └──────┬──────┘
         │
         ▼
  ┌─────────────┐
  │  Manual K8s │  kubectl apply (intentional gate)
  │  Deploy     │  Helm manifests in ./k8s applied after review
  └─────────────┘
       ↑
   CD gap — planned: ArgoCD GitOps (next project)

🗂️ Project Structure
3-tire-CI_CD-DevSecOps/
├── .github/
│   └── workflows/
│       └── ci.yml              # GitHub Actions CI pipeline
├── Terraform/
│   ├── main.tf                 # EKS Auto Mode cluster
│   ├── vpc.tf                  # VPC, subnets, security groups
│   ├── ecr.tf                  # ECR repositories
│   ├── variables.tf
│   └── outputs.tf
├── frontend/                   # React (Vite) app
│   ├── src/
│   ├── Dockerfile              # Multi-stage build → Nginx
│   ├── nginx.conf
│   └── package.json
├── backend/                    # Node.js Express API
│   ├── src/
│   ├── Dockerfile              # Multi-stage build → Node slim
│   └── package.json
├── k8s/                        # Kubernetes manifests (applied manually)
│   ├── frontend-deployment.yml
│   ├── backend-deployment.yml
│   ├── postgres-statefulset.yml
│   ├── ingress.yml
│   └── hpa.yml                 # Horizontal Pod Autoscaler
├── deploy/
│   └── setup.sh               # EC2 bare-metal fallback deploy
└── README.md

🚀 Getting Started
Prerequisites
ToolVersionPurposeTerraform>= 1.6Provision EKS clusterkubectl>= 1.29Deploy to KubernetesAWS CLI>= 2.xAWS authenticationDocker>= 24Local image buildNode.js>= 20Local development
1. Provision Infrastructure (Terraform)
bashcd Terraform

# Initialise with remote state
terraform init

# Review the plan
terraform plan -out=tfplan

# Apply — provisions VPC, EKS, ECR, IAM roles
terraform apply tfplan

EKS Auto Mode handles node provisioning automatically — no node group management needed.

2. Configure kubectl
bashaws eks update-kubeconfig \
  --region ap-south-1 \
  --name jerney-cluster
3. Run CI Pipeline
Push to main or open a PR — the pipeline triggers automatically:
bashgit checkout devops
git add .
git commit -m "feat: your change"
git push origin devops
Pipeline stages run in sequence. A failure at any stage blocks the image from being pushed to ECR.
4. Deploy to Kubernetes (Manual Gate)
After the CI pipeline passes and image is in ECR:
bash# Update image tag in manifests
export IMAGE_TAG=$(git rev-parse --short HEAD)

# Apply manifests
kubectl apply -f k8s/

# Verify pods are running
kubectl get pods -n jerney
kubectl get ingress -n jerney

🔒 Security Controls
StageToolWhat It CatchesCode qualitySonarQubeCode smells, security hotspots, coverage gatesContainer CVEsTrivyHIGH/CRITICAL CVEs in base images and dependenciesSecretsGitHub Secret ScanningAccidental credential commitsIAMLeast-privilege rolesPods use IRSA — no static credentialsNetworkSecurity Groups + NetworkPolicyZero-trust pod-to-pod communication

⚙️ CI Pipeline Configuration
The pipeline is defined in .github/workflows/ci.yml and triggers on:

Push to main or devops branch
Pull requests targeting main

Required GitHub Secrets:
SecretDescriptionAWS_ACCESS_KEY_IDIAM user for ECR pushAWS_SECRET_ACCESS_KEYIAM user secretAWS_REGIONe.g. ap-south-1ECR_REGISTRYYour ECR registry URLSONAR_TOKENSonarCloud project tokenSONAR_HOST_URLSonarQube server URL

🧱 Tech Stack
LayerTechnologyFrontendReact 18, Vite, NginxBackendNode.js 20, ExpressDatabasePostgreSQL 16ContainersDocker (multi-stage builds)OrchestrationKubernetes (AWS EKS Auto Mode)IaCTerraform >= 1.6CIGitHub ActionsSecurity (SAST)SonarQubeSecurity (container)TrivyRegistryAWS ECR

🗺️ Roadmap

 3-tier application (React + Node.js + PostgreSQL)
 Dockerised with multi-stage builds
 Terraform-provisioned EKS Auto Mode cluster
 GitHub Actions CI pipeline with security gates
 SonarQube SAST integration
 Trivy container vulnerability scanning
 Kubernetes manifests with HPA
 ArgoCD GitOps CD — eliminate manual kubectl apply (next project)
 Prometheus + Grafana observability stack
 Slack notifications on pipeline failure


👤 Author
V K Harish Bodapati — DevOps Engineer | AWS | Kubernetes | Terraform
LinkedIn · GitHub
