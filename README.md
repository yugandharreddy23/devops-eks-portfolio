# 📦 DevOps EKS Portfolio: Automated Deployment with Argo CD
A cloud-native DevOps portfolio project using GitOps, EKS, and CI/CD automation
---

## 📁 Repository Structure

```bash
├── .github/workflows/
│   ├── deploy-eks-argocd.yaml        # GitHub Actions pipeline to deploy EKS, Argo CD, and apps
│   └── destroy-eks-argocd.yaml       # GitHub Actions pipeline to destroy the EKS cluster and associated resources
├── terraform/                        # Contains all Terraform configurations
│   ├── main.tf                       # VPC, EKS cluster, and IAM roles definition
│   ├── outputs.tf                    # Terraform output values (e.g., cluster endpoint)
│   ├── provider.tf                   # AWS provider & backend configuration
│   └── variables.tf                  # Input variables (optional if hardcoded)
├── k8s/                              # Kubernetes manifests and Helm charts
│   ├── 2048-app.yaml                 # ArgoCD Application CR for 2048 game
│   ├── 2048-game/                    # Helm chart for deploying the 2048 game
│   │   └── 2048-game/
│   │       ├── Chart.yaml            # Helm chart metadata
│   │       ├── templates/            # Kubernetes templates for 2048 game
│   │       │   ├── _helpers.tpl
│   │       │   ├── deployment.yaml
│   │       │   ├── hpa.yaml
│   │       │   ├── ingress.yaml
│   │       │   ├── NOTES.txt
│   │       │   ├── service.yaml
│   │       │   ├── serviceaccount.yaml
│   │       │   └── tests/
│   │       │       └── test-connection.yaml
│   │       └── values.yaml           # Default Helm chart values
│   ├── argocd/
│   │   ├── bootstrap-apps.yaml       # ArgoCD ApplicationSet for GitOps apps
│   │   └── install.yaml              # Argo CD installation manifest
│   ├── grafana-app.yaml              # ArgoCD Application for Grafana
│   └── prometheus-app.yaml           # ArgoCD Application for Prometheus
├── knownissues.md                    # Known setup errors and troubleshooting guide
├── README.md                         # Primary documentation for deploying the full stack
```

---

## ✅ Pre-requisites

* An AWS Account
* GitHub Account
* Permissions to create EKS, VPC, IAM Roles, and S3 bucket in AWS
* GitHub secrets set:

  * `TF_BACKEND_BUCKET` — S3 bucket name for remote state
  * `TF_BACKEND_REGION` — Region of your deployment (e.g., `us-east-1`)
  * `GITHUB_ROLE_ARN` — IAM Role ARN with GitHub OIDC trust policy and admin permissions

> ⚠️ Important: Ensure the IAM Role created in AWS has `enable_cluster_creator_admin_permissions = true` in your Terraform EKS module.

---

## 🚀 How to Use This Repository

### Step 1: Fork This Repository

1. Click on `Fork` in the top right corner of GitHub
2. Clone your fork locally: `git clone https://github.com/<your-username>/devops-eks-portfolio.git`

### Step 2: Setup AWS Role for GitHub OIDC (One-time setup)

1. Go to **IAM > Roles** and click **Create role**
2. Select **Web Identity**
3. Choose **GitHub** as the provider
4. Set your **GitHub Repo or Org name** (e.g., `yugandharreddy23/devops-eks-portfolio`)
5. Add required IAM policies (e.g., AdministratorAccess or scoped EKS/VPC permissions)
6. Save the **Role ARN**, and store it as `GITHUB_ROLE_ARN` in your GitHub repo secrets

### Step 3: Setup GitHub Secrets

In your repo, go to **Settings > Secrets and Variables > Actions** and set the following:

| Secret Name         | Description                         |
| ------------------- | ----------------------------------- |
| `AWS_REGION`        | AWS Region (e.g., `us-east-1`)      |
| `TF_BACKEND_REGION` | Same as above                       |
| `TF_BACKEND_BUCKET` | S3 bucket name you created manually |
| `GITHUB_ROLE_ARN`   | ARN of your GitHub OIDC IAM Role    |

### Step 4: Trigger Deployment

Commit any changes to the `main` branch or push it — GitHub Actions will:

1. Deploy EKS and VPC via Terraform
2. Install Argo CD
3. Deploy sample apps (Grafana, 2048 game) using Argo CD GitOps
4. Output public endpoints and Argo CD admin password

---

## 🔐 Argo CD Access

Once the pipeline completes, GitHub Actions will automatically print the default Argo CD admin password in the logs.

### Access Argo CD UI:

* Get the public endpoint:

  ```bash
  kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
  ```
* Open in browser: `https://<loadbalancer-hostname>`
* Login with username `admin` and the password retrieved from the pipeline output

---

## 🧩 Applications Deployed

* **Argo CD** (Namespace: `argocd`)
* **Grafana** (Namespace: `monitoring`)
* **2048 Game** (Namespace: `default`)

---

## 🧪 Testing and Validation

After deployment, test access locally:

### Step 1: Configure AWS CLI

```bash
aws configure
```

### Step 2: Update kubeconfig for kubectl

```bash
aws eks update-kubeconfig --region us-east-1 --name devops-eks-portfolio-cluster
```

### Step 3: Validate Kubernetes Access

```bash
kubectl get nodes
kubectl get pods -A
kubectl get svc -A | grep LoadBalancer
```

You should see external LoadBalancer hostnames for:

* ArgoCD
* Grafana
* 2048 Game

### Step 4: Retrieve Argo CD Password (Alternative)

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

---

## 🧹 Resource Cleanup

To destroy all infrastructure and cleanup AWS resources created by Terraform:

1. Navigate to the GitHub Actions tab
2. Run the `destroy-eks-argocd.yaml` workflow manually or trigger it via branch/tag

This workflow will:

* Destroy all Terraform-managed resources (EKS, VPC, IAM roles, etc.)
* Clean up any related Kubernetes objects

---

## 🛠️ Additional Automation

The following automation is already configured in the GitHub Actions workflow:

* Argo CD server exposed via LoadBalancer
* Namespace creation and app deployment
* Dynamic waiting for LoadBalancer IPs
* Auto-retrieval of Argo CD admin password (prints to pipeline logs)
* Display of ArgoCD, Grafana, and 2048 Game public endpoints

---

## 📌 Notes

* Cluster will fail if `enable_cluster_creator_admin_permissions = false`
* The `aws-auth` patch step is critical to allow GitHub Actions to run `kubectl`
* Terraform stores state in S3 — ensure S3 bucket exists before running the pipeline

---

## 📄 Licensing

MIT License — Free to use, share, modify.

---

For advanced troubleshooting and known issues, refer to [`KNOWN_ISSUES.md`](./KNOWN_ISSUES.md)

---

Happy DevOps-ing! 🚀
