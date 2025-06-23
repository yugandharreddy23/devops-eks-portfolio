FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

# Install system dependencies
RUN apt-get update && apt-get install -y \
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
    bash-completion \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Set up workspace directory
WORKDIR /workspace

# Set environment variables
ENV TF_PLUGIN_CACHE_DIR=/tmp/terraform-plugin-cache
ENV WORKSPACE_FOLDER=/workspace

# Expose common ports
EXPOSE 3000 8080 9090 3001

# Copy setup script
COPY setup.sh /tmp/setup.sh
RUN chmod +x /tmp/setup.sh

# Switch to non-root user
USER $USERNAME

# Set default shell to zsh
SHELL ["/bin/zsh", "-c"]