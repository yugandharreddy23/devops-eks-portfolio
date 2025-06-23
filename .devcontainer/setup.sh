#!/bin/bash
set -e

echo "🚀 Starting DevContainer setup for DevOps EKS Portfolio..."

# Update system packages
echo "📦 Updating system packages..."
sudo apt-get update && sudo apt-get upgrade -y

# Install essential packages
echo "🔧 Installing essential packages..."
sudo apt-get install -y \
    curl \
    wget \
    unzip \
    git \
    jq \
    tree \
    htop \
    vim \
    nano \
    build-essential \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    bash-completion

# Install AWS CLI v2
echo "☁️ Installing AWS CLI v2..."
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf awscliv2.zip aws/
    echo "✅ AWS CLI installed successfully"
else
    echo "✅ AWS CLI already installed"
fi

# Install Terraform
echo "🏗️ Installing Terraform..."
if ! command -v terraform &> /dev/null; then
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt-get update && sudo apt-get install -y terraform
    echo "✅ Terraform installed successfully"
else
    echo "✅ Terraform already installed"
fi

# Install kubectl
echo "⚓ Installing kubectl..."
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    echo "✅ kubectl installed successfully"
else
    echo "✅ kubectl already installed"
fi

# Install Helm
echo "⛵ Installing Helm..."
if ! command -v helm &> /dev/null; then
    curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
    sudo apt-get update && sudo apt-get install -y helm
    echo "✅ Helm installed successfully"
else
    echo "✅ Helm already installed"
fi

# Install eksctl
echo "🎯 Installing eksctl..."
if ! command -v eksctl &> /dev/null; then
    ARCH=amd64
    PLATFORM=$(uname -s)_$ARCH
    curl -sLO "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
    tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz
    sudo mv /tmp/eksctl /usr/local/bin
    echo "✅ eksctl installed successfully"
else
    echo "✅ eksctl already installed"
fi

# Install k9s (Kubernetes CLI UI)
echo "🐕 Installing k9s..."
if ! command -v k9s &> /dev/null; then
    K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | jq -r '.tag_name')
    curl -sL "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz" | sudo tar xzf - -C /usr/local/bin k9s
    echo "✅ k9s installed successfully"
else
    echo "✅ k9s already installed"
fi

# Install kubectx and kubens
echo "🔄 Installing kubectx and kubens..."
if ! command -v kubectx &> /dev/null; then
    sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
    sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
    sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens
    echo "✅ kubectx and kubens installed successfully"
else
    echo "✅ kubectx and kubens already installed"
fi

# Install Istioctl
echo "🕸️ Installing Istioctl..."
if ! command -v istioctl &> /dev/null; then
    curl -L https://istio.io/downloadIstio | sh -
    sudo mv istio-*/bin/istioctl /usr/local/bin/
    rm -rf istio-*
    echo "✅ Istioctl installed successfully"
else
    echo "✅ Istioctl already installed"
fi

# Install Terraform providers cache directory
echo "💾 Setting up Terraform plugin cache..."
mkdir -p /tmp/terraform-plugin-cache
export TF_PLUGIN_CACHE_DIR=/tmp/terraform-plugin-cache

# Install Node.js dependencies for potential frontend components
echo "📱 Installing global Node.js packages..."
npm install -g \
    @aws-cdk/aws-cdk \
    aws-cdk \
    typescript \
    @types/node \
    prettier \
    eslint

# Install Python packages for automation scripts
echo "🐍 Installing Python packages..."
pip3 install --user \
    boto3 \
    kubernetes \
    pyyaml \
    requests \
    click \
    rich \
    pytest \
    black \
    flake8

# Setup shell completions
echo "🎨 Setting up shell completions..."
# kubectl completion
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
kubectl completion zsh > ~/.zsh_kubectl_completion
echo 'source ~/.zsh_kubectl_completion' >> ~/.zshrc

# helm completion
helm completion bash | sudo tee /etc/bash_completion.d/helm > /dev/null
helm completion zsh > ~/.zsh_helm_completion
echo 'source ~/.zsh_helm_completion' >> ~/.zshrc

# terraform completion
terraform -install-autocomplete || true

# eksctl completion
eksctl completion bash | sudo tee /etc/bash_completion.d/eksctl > /dev/null
eksctl completion zsh > ~/.zsh_eksctl_completion
echo 'source ~/.zsh_eksctl_completion' >> ~/.zshrc

# Add useful aliases
echo "🔗 Adding useful aliases..."
cat >> ~/.zshrc << 'EOF'

# DevOps aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kgn='kubectl get nodes'
alias kga='kubectl get all'
alias kdp='kubectl describe pod'
alias kds='kubectl describe service'
alias kdd='kubectl describe deployment'
alias kl='kubectl logs'
alias ke='kubectl exec -it'
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias tfv='terraform validate'
alias tff='terraform fmt'
alias aws-whoami='aws sts get-caller-identity'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gm='git merge'
alias gr='git remote -v'

EOF

# Create useful directories
echo "📁 Creating project directories..."
mkdir -p ~/workspace/{terraform,kubernetes,scripts,docs,charts}

# Display installed versions
echo "🎉 Installation complete! Here are the installed tool versions:"
echo "----------------------------------------"
echo "AWS CLI: $(aws --version 2>&1 | head -n1)"
echo "Terraform: $(terraform version | head -n1)"
echo "kubectl: $(kubectl version --client --short 2>/dev/null || echo 'kubectl client version')"
echo "Helm: $(helm version --short 2>/dev/null || echo 'Helm version')"
echo "eksctl: $(eksctl version)"
echo "k9s: $(k9s version --short 2>/dev/null || echo 'k9s version')"
echo "Node.js: $(node --version)"
echo "Python: $(python3 --version)"
echo "Docker: $(docker --version 2>/dev/null || echo 'Docker not available in container')"
echo "----------------------------------------"

echo "✨ DevContainer setup completed successfully!"
echo "🎯 You're ready to start working on your DevOps EKS portfolio project!"
echo ""
echo "📖 Quick start commands:"
echo "  - aws configure          # Configure AWS credentials"
echo "  - kubectl cluster-info   # Check cluster connection"
echo "  - terraform init         # Initialize Terraform"
echo "  - k9s                    # Launch Kubernetes UI"
<<<<<<< HEAD
echo ""
=======
echo ""
>>>>>>> a49eb48 (Adding required files)
