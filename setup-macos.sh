#!/bin/bash

################################################################################
# macOS Development Environment Setup Script
# Migrated from Linux (setup.sh) to macOS
# This script sets up a complete DevOps and development environment on macOS
# It is idempotent - safe to run multiple times
################################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}▶ $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_step() {
    echo -e "${CYAN}→ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Install Xcode Command Line Tools (macOS equivalent of build-essential)
install_xcode_cli_tools() {
    print_header "Step 0: Installing Xcode Command Line Tools"

    if xcode-select -p &>/dev/null; then
        print_info "Xcode Command Line Tools are already installed"
    else
        print_step "Installing Xcode Command Line Tools..."
        xcode-select --install || true
        print_info "If a GUI dialog appeared, please complete the installation and re-run this script"
        print_success "Xcode Command Line Tools setup initiated"
    fi
}

# Check if Homebrew is installed, install if not
install_homebrew() {
    print_header "Step 1: Installing Homebrew"

    if command -v brew &> /dev/null; then
        print_success "Homebrew is already installed"
        print_step "Updating Homebrew..."
        brew update
        print_success "Homebrew updated"
    else
        print_info "Homebrew not found. Installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for Apple Silicon (ARM64) Macs
        if [[ $(uname -m) == "arm64" ]]; then
            if ! grep -q '/opt/homebrew/bin' "$HOME/.zprofile" 2>/dev/null; then
                echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
        fi

        print_success "Homebrew installed successfully"
    fi
}

# Install DevOps CLI Tools (migrated from Linux setup.sh + requested tools)
install_brew_packages() {
    print_header "Step 2: Installing DevOps CLI Tools"

    local packages=(
        # Core tools (from original Linux setup)
        "git"
        "git-lfs"
        "curl"
        "wget"
        "zsh"
        "vim"
        "jq"
        "htop"
        "tree"

        # DevOps essentials (explicitly requested)
        "ansible"
        "terraform"
        "kubectl"
        "helm"
        "awscli"
        "yq"

        # Kubernetes utilities (migrated from Linux)
        "k9s"
        "eks-node-viewer"

        # Containers
        "docker"
        "docker-compose"

        # Databases (from original Linux setup)
        "mysql-client"
        "postgresql@14"
        "redis"

        # Development languages
        "python"
        "node"

        # Additional DevOps utilities (from pre-existing macOS workflow)
        "vault"
        "consul"
        "nomad"
        "packer"
        "direnv"
        "gnupg"
        "shellcheck"
        "aws-vault"
    )

    for package in "${packages[@]}"; do
        if brew list "$package" &>/dev/null; then
            print_info "$package is already installed"
        else
            print_step "Installing $package..."
            brew install "$package"
            print_success "$package installed"
        fi
    done

    print_success "All DevOps CLI tools installed"
}

# Install macOS GUI Applications via Homebrew Cask
install_cask_apps() {
    print_header "Step 3: Installing macOS Applications (Cask)"

    local apps=(
        "iterm2"
        "visual-studio-code"
        "docker"
        "slack"
        "notion"
        "postman"
        "sequel-pro"
        "dbeaver-community"
        "microsoft-teams"
    )

    for app in "${apps[@]}"; do
        if brew list --cask "$app" &>/dev/null; then
            print_info "$app is already installed"
        else
            print_step "Installing $app..."
            brew install --cask "$app"
            print_success "$app installed"
        fi
    done

    print_success "All cask applications installed"
}

# Install AWS VPN Client manually (not available via Homebrew Cask)
install_aws_vpn_client() {
    print_header "Step 3b: Installing AWS VPN Client"

    local vpn_app="/Applications/AWS VPN Client/AWS VPN Client.app"
    if [ -d "$vpn_app" ]; then
        print_info "AWS VPN Client is already installed"
        return 0
    fi

    local tmp_dir
    tmp_dir=$(mktemp -d)
    local pkg_file="$tmp_dir/aws_vpn_client.pkg"

    # Detect architecture and download the correct package
    if [[ $(uname -m) == "arm64" ]]; then
        print_step "Detected Apple Silicon (ARM64). Downloading AWS VPN Client..."
        curl -fsSL -o "$pkg_file" "https://d20adtppz83p9s.cloudfront.net/OSX_ARM64/latest/AWS_VPN_Client_ARM64.pkg"
    else
        print_step "Detected Intel (x64). Downloading AWS VPN Client..."
        curl -fsSL -o "$pkg_file" "https://d20adtppz83p9s.cloudfront.net/OSX/latest/AWS_VPN_Client.pkg"
    fi

    print_step "Installing AWS VPN Client from pkg..."
    sudo installer -pkg "$pkg_file" -target /
    rm -rf "$tmp_dir"

    print_success "AWS VPN Client installed successfully"
}

# Setup Oh-My-Zsh with plugins
setup_zsh() {
    print_header "Step 4: Setting up Zsh and Oh-My-Zsh"

    # Ensure zsh is the default shell
    if [[ "$SHELL" != "$(which zsh)" ]]; then
        print_step "Setting Zsh as the default shell..."
        chsh -s "$(which zsh)"
        print_success "Zsh set as default shell"
    else
        print_info "Zsh is already the default shell"
    fi

    # Install oh-my-zsh if not present
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        print_step "Installing Oh-My-Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        print_success "Oh-My-Zsh installed"
    else
        print_info "Oh-My-Zsh is already installed"
    fi

    # Install zsh-autosuggestions
    local autosuggestions_path="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
    if [ ! -d "$autosuggestions_path" ]; then
        print_step "Installing zsh-autosuggestions plugin..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$autosuggestions_path"
        print_success "zsh-autosuggestions installed"
    else
        print_info "zsh-autosuggestions is already installed"
    fi

    # Install zsh-syntax-highlighting
    local syntax_path="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    if [ ! -d "$syntax_path" ]; then
        print_step "Installing zsh-syntax-highlighting plugin..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$syntax_path"
        print_success "zsh-syntax-highlighting installed"
    else
        print_info "zsh-syntax-highlighting is already installed"
    fi

    print_success "Zsh setup complete"
}

# Configure Git and GitHub CLI
configure_git() {
    print_header "Step 5: Configuring Git"

    # Install GitHub CLI if not present
    if ! command -v gh &> /dev/null; then
        print_step "Installing GitHub CLI..."
        brew install gh
        print_success "GitHub CLI installed"
    else
        print_info "GitHub CLI is already installed"
    fi

    # Configure Git LFS
    if ! command -v git-lfs &> /dev/null; then
        print_step "Installing Git LFS..."
        brew install git-lfs
        git lfs install
        print_success "Git LFS installed and configured"
    else
        print_info "Git LFS is already installed"
    fi

    print_success "Git configuration complete"
}

# Install additional Node.js tools and global npm packages
install_node_tools() {
    print_header "Step 6: Installing Node.js Tools"

    # Install nvm for better Node version management
    if [ ! -d "$HOME/.nvm" ]; then
        print_step "Installing nvm (Node Version Manager)..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        print_success "nvm installed"
    else
        print_info "nvm is already installed"
    fi

    # Source nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Install LTS Node.js if not present
    if command -v node &> /dev/null; then
        print_info "Node.js is already installed: $(node --version)"
    else
        print_step "Installing Node.js LTS..."
        nvm install --lts
        nvm use --lts
        print_success "Node.js LTS installed"
    fi

    # Install useful npm global tools (from pre-existing macOS workflow)
    local npm_tools=("pnpm" "yarn" "typescript" "ts-node" "pm2")
    for tool in "${npm_tools[@]}"; do
        if npm list -g "$tool" &>/dev/null; then
            print_info "$tool is already installed globally"
        else
            print_step "Installing $tool globally..."
            npm install -g "$tool"
            print_success "$tool installed globally"
        fi
    done

    print_success "Node.js tools installed"
}

# Cleanup function
cleanup() {
    print_header "Step 7: Cleanup"

    print_step "Running brew cleanup..."
    brew cleanup || true

    print_success "Cleanup complete"
}

# Main execution
main() {
    print_header "macOS Development Environment Setup"
    print_info "This script will configure your macOS development environment"
    print_info "Based on your original Linux setup.sh"

    # Check if running on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script is designed for macOS only"
        exit 1
    fi

    # Execute installation steps
    install_xcode_cli_tools
    install_homebrew
    install_brew_packages
    install_cask_apps
    install_aws_vpn_client
    setup_zsh
    configure_git
    install_node_tools
    cleanup

    print_header "Setup Complete!"
    print_success "Your macOS development environment is ready"
    print_info "Next steps:"
    echo -e "  1. Enable zsh plugins in ~/.zshrc: plugins=(git zsh-autosuggestions zsh-syntax-highlighting)"
    echo -e "  2. Configure your Git identity:"
    echo -e "     git config --global user.name 'Your Name'"
    echo -e "     git config --global user.email 'your.email@example.com'"
    echo -e "  3. Restart your terminal or run: source ~/.zshrc"
    echo -e "  4. Log out and back in for Docker Desktop and shell changes to fully apply"
    echo -e "\n${GREEN}Happy coding!${NC}\n"
}

# Run main function
main "$@"
