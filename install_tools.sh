#!/bin/bash

###########################################
# Recon Tools Installation Script
# Installs all dependencies for recon automation
###########################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[+]${NC} $1"; }
print_error() { echo -e "${RED}[-]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }

echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║     Recon Tools Installation Script                      ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check if running as root for system packages
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        print_warning "Some installations require root privileges"
        print_warning "You may be prompted for sudo password"
    fi
}

# Install system dependencies
install_system_deps() {
    print_status "Installing system dependencies..."
    
    if [ -f /etc/debian_version ]; then
        sudo apt update
        sudo apt install -y curl wget git build-essential python3 python3-pip jq nmap chromium-browser
        print_success "System dependencies installed (Debian/Ubuntu)"
    elif [ -f /etc/redhat-release ]; then
        sudo yum install -y curl wget git gcc make python3 python3-pip jq nmap chromium
        print_success "System dependencies installed (RedHat/CentOS)"
    elif [ "$(uname)" == "Darwin" ]; then
        if ! command -v brew &> /dev/null; then
            print_error "Homebrew not found. Please install from https://brew.sh"
            exit 1
        fi
        brew install curl wget git jq nmap chromium
        print_success "System dependencies installed (macOS)"
    else
        print_warning "Unknown OS. Please install manually: curl wget git jq nmap chromium"
    fi
}

# Install Go
install_go() {
    if command -v go &> /dev/null; then
        print_success "Go is already installed ($(go version))"
        return
    fi
    
    print_status "Installing Go..."
    
    GO_VERSION="1.21.5"
    
    if [ "$(uname)" == "Darwin" ]; then
        wget "https://go.dev/dl/go${GO_VERSION}.darwin-amd64.tar.gz" -O /tmp/go.tar.gz
    else
        wget "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -O /tmp/go.tar.gz
    fi
    
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    rm /tmp/go.tar.gz
    
    # Add to PATH
    echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.bashrc
    echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.zshrc 2>/dev/null
    
    export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
    
    print_success "Go installed successfully"
}

# Install Go-based tools
install_go_tools() {
    print_status "Installing Go-based reconnaissance tools..."
    
    # Ensure Go bin is in PATH
    export PATH=$PATH:$(go env GOPATH)/bin
    
    print_status "Installing subfinder..."
    go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
    
    print_status "Installing assetfinder..."
    go install -v github.com/tomnomnom/assetfinder@latest
    
    print_status "Installing httpx..."
    go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
    
    print_status "Installing naabu..."
    go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
    
    print_status "Installing gau..."
    go install -v github.com/lc/gau/v2/cmd/gau@latest
    
    print_status "Installing waybackurls..."
    go install -v github.com/tomnomnom/waybackurls@latest
    
    print_status "Installing ffuf..."
    go install -v github.com/ffuf/ffuf/v2@latest
    
    print_status "Installing gowitness..."
    go install -v github.com/sensepost/gowitness@latest
    
    print_status "Installing nuclei..."
    go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
    
    print_success "Go-based tools installed"
}

# Install Amass
install_amass() {
    print_status "Installing Amass..."
    
    if [ -f /etc/debian_version ]; then
        sudo apt install -y amass
    elif [ -f /etc/redhat-release ]; then
        sudo yum install -y amass
    elif [ "$(uname)" == "Darwin" ]; then
        brew install amass
    else
        # Install from source
        go install -v github.com/owasp-amass/amass/v4/...@master
    fi
    
    print_success "Amass installed"
}

# Install Python tools (optional)
install_python_tools() {
    print_status "Installing Python-based tools (optional)..."
    
    # EyeWitness
    if [ ! -d ~/tools/EyeWitness ]; then
        print_status "Installing EyeWitness..."
        mkdir -p ~/tools
        cd ~/tools
        git clone https://github.com/FortyNorthSecurity/EyeWitness.git
        cd EyeWitness/Python/setup
        sudo ./setup.sh
        cd ~
        print_success "EyeWitness installed"
    else
        print_success "EyeWitness already installed"
    fi
}

# Download wordlists
install_wordlists() {
    print_status "Downloading wordlists..."
    
    sudo mkdir -p /usr/share/wordlists
    
    if [ ! -d /usr/share/wordlists/SecLists ]; then
        print_status "Downloading SecLists..."
        sudo git clone https://github.com/danielmiessler/SecLists.git /usr/share/wordlists/SecLists
        print_success "SecLists downloaded"
    else
        print_success "SecLists already exists"
    fi
    
    # Common dirb wordlist
    if [ ! -d /usr/share/wordlists/dirb ]; then
        sudo mkdir -p /usr/share/wordlists/dirb
        sudo wget https://raw.githubusercontent.com/v0re/dirb/master/wordlists/common.txt -O /usr/share/wordlists/dirb/common.txt
        print_success "Dirb wordlist downloaded"
    fi
}

# Verify installations
verify_tools() {
    print_status "Verifying tool installations..."
    
    local tools=("subfinder" "assetfinder" "amass" "nmap" "naabu" "httpx" "gau" "waybackurls" "ffuf" "gowitness" "nuclei")
    local failed=()
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            print_success "$tool ✓"
        else
            print_error "$tool ✗"
            failed+=("$tool")
        fi
    done
    
    if [ ${#failed[@]} -eq 0 ]; then
        print_success "All tools installed successfully!"
    else
        print_warning "Some tools failed to install: ${failed[*]}"
        print_warning "You may need to install them manually"
    fi
}

# Create API config directories
setup_configs() {
    print_status "Creating configuration directories..."
    
    mkdir -p ~/.config/subfinder
    mkdir -p ~/.config/amass
    mkdir -p ~/.config/nuclei
    
    # Create sample subfinder config
    if [ ! -f ~/.config/subfinder/config.yaml ]; then
        cat > ~/.config/subfinder/config.yaml << 'EOF'
# Subfinder Configuration
# Add your API keys here for enhanced results

# Example:
# virustotal: ["your-api-key-here"]
# censys: ["api-id", "api-secret"]
# shodan: ["api-key"]
# github: ["token1", "token2"]
EOF
        print_success "Subfinder config template created"
        print_warning "Add your API keys to ~/.config/subfinder/config.yaml for better results"
    fi
}

# Main installation
main() {
    check_root
    
    echo ""
    print_warning "This will install multiple tools and may take several minutes"
    read -p "Continue? (y/n): " continue_install
    
    if [[ ! "$continue_install" =~ ^[Yy]$ ]]; then
        print_error "Installation cancelled"
        exit 0
    fi
    
    install_system_deps
    install_go
    install_go_tools
    install_amass
    
    echo ""
    read -p "Install Python tools (EyeWitness)? (y/n): " install_py
    if [[ "$install_py" =~ ^[Yy]$ ]]; then
        install_python_tools
    fi
    
    echo ""
    read -p "Download wordlists (SecLists ~500MB)? (y/n): " install_wl
    if [[ "$install_wl" =~ ^[Yy]$ ]]; then
        install_wordlists
    fi
    
    setup_configs
    
    echo ""
    verify_tools
    
    echo ""
    print_success "Installation complete!"
    print_warning "Please restart your terminal or run: source ~/.bashrc"
    print_warning "Then verify with: subfinder -version"
}

main "$@"
