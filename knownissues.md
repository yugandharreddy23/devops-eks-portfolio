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

### 5. ✅ **Final State**

* Port-forwarding successful
* Logged into ArgoCD UI
* Able to invalidate cache and read logs

---

This log will be updated as new issues arise. Consider adding it to your GitHub repo’s `/docs/` directory with links from your `README.md`.
