# EKS DevOps Portfolio: Known Issues and Fixes

This document captures all the key issues encountered during the deployment of an EKS-based DevOps portfolio project using Fargate, ArgoCD, and other cloud-native tools. It includes both the symptoms and solutions, structured for quick debugging and ease of onboarding.

---

## 🟠 Cluster Setup & EKS Fargate Initialization

### 1. ❌ **`nslookup` or `dig` not found in debug containers**

* **Cause**: Base images like `busybox` or `alpine` used for debugging do not include these tools.
* **Solution**:

  ```bash
  kubectl run debug --image=ghcr.io/nicolaka/netshoot --rm -it -- bash
  ```

  Use `netshoot` or another debug image with proper network tooling.

### 2. ❌ **FailedScheduling: untolerated taint `{eks.amazonaws.com/compute-type: fargate}`**

* **Cause**: No matching Fargate profile for the pod namespace and label selector.
* **Solution**:

  * Define a proper Fargate profile in Terraform or AWS console with matching namespace.
  * Wait \~2–3 mins for the profile to become active.

---

## 🟠 CoreDNS & Networking Issues

### 1. ❌ **CoreDNS Pods stuck in `Pending`**

* **Cause**: No Fargate profile configured for `kube-system` namespace.
* **Solution**:

  * Create a new Fargate profile with `namespace: kube-system`
  * Confirm pods get scheduled:

    ```bash
    kubectl get pods -n kube-system -l k8s-app=kube-dns
    ```

### 2. ❌ **DNS resolution errors inside pods**

* **Errors**:

  ```
  lookup argocd-redis on 172.20.0.10:53: connection refused
  ```
* **Cause**: CoreDNS not running.
* **Solution**: Ensure CoreDNS is `Running` (see above fix). DNS becomes available once CoreDNS is healthy.

---

## 🟠 ArgoCD Deployment & Access

### 1. ❌ **`argocd-server` CrashLoopBackOff**

* **Cause**: Incorrect usage of both `command` and `args` in the pod spec.
* **Solution**:

  * Avoid overriding both unless absolutely needed.
  * Use:

    ```yaml
    command: ["argocd-server"]
    args: ["--insecure"]
    ```

### 2. ❌ **Two ArgoCD server pods running**

* **Cause**: Old deployment wasn't deleted properly.
* **Solution**: Clean up namespace before reinstall:

  ```bash
  kubectl delete ns argocd
  kubectl create ns argocd
  ```

### 3. ❌ **Cannot access ArgoCD UI after port-forwarding**

* **Solution**:

  * Confirm port-forward:

    ```bash
    kubectl port-forward svc/argocd-server -n argocd 8080:443
    ```
  * Ensure ArgoCD is using `--insecure` flag if forwarding to HTTP.

### 4. ❌ **Missing `argocd-initial-admin-secret`**

* **Cause**: ArgoCD was reset or redeployed.
* **Solution**:

  * Create a new bcrypt hash:

    ```bash
    python3 -m pip install bcrypt
    python3 -c "import bcrypt; print(bcrypt.hashpw(b'MySecurePassword123', bcrypt.gensalt()).decode())"
    ```
  * Patch secret:

    ```bash
    kubectl -n argocd patch secret argocd-secret \
      -p '{"stringData": {"admin.password": "$2y$...", "admin.passwordMtime": "2025-06-24T00:00:00Z"}}'
    ```
## ⚙️ Terraform & AWS Integration

### 1. ❌ `InvalidLocationConstraint` when creating S3 bucket

- **Cause**: The region specified in bucket creation does not match the S3 regional rules (e.g., `us-east-1` should not have a `LocationConstraint`).
- **Fix**: Create the bucket manually via console **without** setting location for `us-east-1`.

---

### 2. ❌ Terraform state not found in S3

- **Cause**: The backend S3 bucket is not created or misconfigured.
- **Fix**: Manually create the S3 bucket and store its name in GitHub secret `TF_BACKEND_BUCKET`.

---

### 3. ❌ `AlreadyExistsException` on `aws_kms_alias`

- **Cause**: Repeated runs without destroying existing KMS keys or aliases.
- **Fix**: Manually delete the conflicting alias in AWS KMS console.

---

### 4. ❌ `AddressLimitExceeded` for `aws_eip.nat`

- **Cause**: EIP quota exceeded in AWS account.
- **Fix**: Request EIP quota increase or reduce number of NAT gateways/subnets.

---

## ☁️ EKS Cluster Issues

### 1. ❌ Cluster created but `kubectl` access fails (`Unauthorized`)

- **Cause**: IAM role used by GitHub does not have system:masters access.
- **Fix**: Set `enable_cluster_creator_admin_permissions = true` in the EKS module.

---

### 2. ❌ `aws-auth` patch fails with credential error

- **Cause**: GitHub runner not authenticated to EKS due to missing OIDC permissions.
- **Fix**: Ensure correct `GITHUB_ROLE_ARN` and that it’s mapped in `aws-auth`.

---

### 3. ❌ GitHub OIDC role setup fails or GitHub can’t assume it

- **Cause**: Web identity role is restricted to an organization; your repo is personal.
- **Fix**: While creating IAM Role:
  - Set **Provider** to GitHub
  - Use `repo:<username>/<repo>:ref:refs/heads/main` in condition
