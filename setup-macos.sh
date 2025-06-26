#!/bin/bash
set -e

echo "🚀 Starting setup for DevOps EKS Portfolio on macOS..."

# For Apple Silicon (M1/M2/M3/M4): Ensure Homebrew is in PATH
if [[ $(uname -m) == 'arm64' ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    if ! grep -q '/opt/homebrew/bin' ~/.zprofile 2>/dev/null; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    fi
fi

# Check for Homebrew and install if missing
if ! command -v brew &> /dev/null; then
    echo "🍺 Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add Homebrew to PATH for current session
    if [[ $(uname -m) == 'arm64' ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
else
    echo "🍺 Homebrew already installed"
fi

echo "📦 Updating Homebrew..."
brew update

# Essential packages
echo "🔧 Installing essential packages..."
brew install \
    curl \
    wget \
    unzip \
    git \
    jq \
    tree \
    htop \
    vim \
    nano \
    bash-completion \
    python \
    node \
    awscli \
    terraform \
    kubectl \
    helm \
    k9s

# Install eksctl
echo "🎯 Installing eksctl..."
brew tap weaveworks/tap
brew install weaveworks/tap/eksctl

# Install kubectx and kubens
echo "🔄 Installing kubectx and kubens..."
brew install kubectx

# Install Istioctl
echo "🕸️ Installing istioctl..."
brew install istioctl

# Node.js global packages
echo "📱 Installing global Node.js packages..."
npm install -g \
    aws-cdk \
    typescript \
    @types/node \
    prettier \
    eslint

# Python packages
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

# Add useful aliases to ~/.zshrc
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
echo "Docker: $(docker --version 2>/dev/null || echo 'Docker not available')"
echo "----------------------------------------"

echo "✨ Setup completed successfully!"
echo "🎯 You're ready to start working on your DevOps EKS portfolio project!"
echo ""
echo "📖 Quick start commands:"
echo "  - aws configure          # Configure AWS credentials"
echo "  - kubectl cluster-info   # Check cluster connection"
echo "  - terraform init         # Initialize Terraform"
echo "  - k9s                    # Launch Kubernetes UI"
echo ""