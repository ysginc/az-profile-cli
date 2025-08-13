#!/bin/bash

# Azure CLI Profile Manager - Installation Script
# Automates installation on Linux machines with style! 🚀

set -e

# Colors for beautiful output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/ysginc/az-profile-cli"
DEFAULT_INSTALL_DIR="$HOME/.local/bin"
DEFAULT_CONFIG_DIR="$HOME/.config/az-profile-cli"
DEFAULT_REPO_DIR="$HOME/.local/share/az-profile-cli"
PROFILES_DIR="$HOME/.az-profiles"

# Helper functions
print_banner() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}           🚀 Azure CLI Profile Manager Installer             ${CYAN}║${NC}"
    echo -e "${CYAN}║                                                              ║${NC}"
    echo -e "${CYAN}║${YELLOW}        Making Azure environment switching awesome!           ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

check_prerequisites() {
    log_step "Checking prerequisites..."
    
    local missing_deps=()
    
    # Check for required commands
    if ! command -v bash >/dev/null 2>&1; then
        missing_deps+=("bash")
    fi
    
    if ! command -v git >/dev/null 2>&1; then
        missing_deps+=("git")
    fi
    
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        missing_deps+=("curl or wget")
    fi
    
    # Check for Azure CLI (warn if missing, don't fail)
    if ! command -v az >/dev/null 2>&1; then
        log_warning "Azure CLI not found. You'll need to install it to use the profile manager."
        log_info "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        echo ""
    else
        local az_version=$(az version --query '"azure-cli"' -o tsv 2>/dev/null || echo "unknown")
        log_success "Azure CLI found: version $az_version"
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_info "Please install them and run this script again."
        exit 1
    fi
    
    log_success "All prerequisites satisfied!"
    echo ""
}

detect_shell() {
    local shell_name=$(basename "$SHELL")
    local shell_config=""
    
    case "$shell_name" in
        bash)
            if [ -f "$HOME/.bashrc" ]; then
                shell_config="$HOME/.bashrc"
            elif [ -f "$HOME/.bash_profile" ]; then
                shell_config="$HOME/.bash_profile"
            fi
            ;;
        zsh)
            shell_config="$HOME/.zshrc"
            ;;
        fish)
            shell_config="$HOME/.config/fish/config.fish"
            ;;
        *)
            log_warning "Unknown shell: $shell_name. You'll need to manually add to your shell config."
            return 1
            ;;
    esac
    
    if [ -z "$shell_config" ]; then
        log_warning "No shell configuration file found for $shell_name."
        return 1
    fi
    
    echo "$shell_config"
}

prompt_user() {
    local prompt="$1"
    local default="$2"
    local response
    
    if [ -n "$default" ]; then
        echo -ne "${CYAN}$prompt${NC} ${YELLOW}[$default]${NC}: " >&2
    else
        echo -ne "${CYAN}$prompt${NC}: " >&2
    fi
    
    read -r response
    
    if [ -z "$response" ] && [ -n "$default" ]; then
        response="$default"
    fi
    
    echo "$response"
}

install_files() {
    log_step "Installing Azure CLI Profile Manager..."
    
    # Determine installation method
    local install_method=""
    if [ -n "$INSTALL_FROM_LOCAL" ]; then
        install_method="local"
    else
        install_method="git"
    fi
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$PROFILES_DIR"
    
    case "$install_method" in
        "local")
            log_info "Installing from local directory: $INSTALL_FROM_LOCAL"
            if [ ! -d "$INSTALL_FROM_LOCAL" ]; then
                log_error "Local directory not found: $INSTALL_FROM_LOCAL"
                exit 1
            fi
            cp "$INSTALL_FROM_LOCAL/az-profile" "$INSTALL_DIR/"
            cp "$INSTALL_FROM_LOCAL/az-profile-helpers.sh" "$CONFIG_DIR/"
            if [ -d "$INSTALL_FROM_LOCAL/examples" ]; then
                cp -r "$INSTALL_FROM_LOCAL/examples" "$CONFIG_DIR/"
            fi
            ;;
        "git")
            log_info "Cloning from repository: $REPO_URL"
            
            # Create repo directory if it doesn't exist
            mkdir -p "$(dirname "$DEFAULT_REPO_DIR")"
            
            # Clone or update repository
            if [ -d "$DEFAULT_REPO_DIR/.git" ]; then
                log_info "Repository already exists, updating..."
                (
                    cd "$DEFAULT_REPO_DIR" && git pull >/dev/null 2>&1
                ) &
                spinner $!
            else
                # Clone with progress
                (
                    git clone "$REPO_URL" "$DEFAULT_REPO_DIR" >/dev/null 2>&1
                ) &
                spinner $!
            fi
            
            if [ ! -d "$DEFAULT_REPO_DIR" ] || [ ! -f "$DEFAULT_REPO_DIR/az-profile" ]; then
                log_error "Failed to clone repository or files are missing"
                rm -rf "$DEFAULT_REPO_DIR"
                exit 1
            fi
            
            # Create symlinks instead of copying files
            ln -sf "$DEFAULT_REPO_DIR/az-profile" "$INSTALL_DIR/az-profile"
            ln -sf "$DEFAULT_REPO_DIR/az-profile-helpers.sh" "$CONFIG_DIR/az-profile-helpers.sh"
            if [ -d "$DEFAULT_REPO_DIR/examples" ]; then
                # Remove existing examples directory to avoid conflicts with symlink
                rm -rf "$CONFIG_DIR/examples"
                ln -sf "$DEFAULT_REPO_DIR/examples" "$CONFIG_DIR/examples"
            fi
            ;;
    esac
    
    # Make executable
    chmod +x "$INSTALL_DIR/az-profile"
    
    log_success "Files installed successfully!"
    echo ""
}

strip_ansi_codes() {
    # Remove ANSI escape sequences from string
    echo "$1" | sed 's/\x1b\[[0-9;]*m//g'
}

setup_shell_integration() {
    log_step "Setting up shell integration..."
    
    local shell_config=$(detect_shell)
    if [ $? -ne 0 ]; then
        log_warning "Could not detect shell configuration file."
        log_info "You'll need to manually add the following to your shell config:"
        echo -e "${YELLOW}  source $CONFIG_DIR/az-profile-helpers.sh${NC}"
        echo -e "${YELLOW}  export PATH=\"$INSTALL_DIR:\$PATH\"${NC}"
        echo ""
        return 0
    fi
    
    log_info "Detected shell config: $shell_config"
    
    # Check if already configured
    if grep -q "az-profile-helpers.sh" "$shell_config" 2>/dev/null; then
        log_warning "Shell integration already configured in $shell_config"
        return 0
    fi
    
    # Ask user if they want automatic setup
    echo ""
    
    # Create a simple, fixed-width shell configuration dialog
    local box_width=63
    local total_content_width=$((box_width - 2))  # Account for left and right borders: │content│
    
    echo -e "${CYAN}╭─ Shell Configuration ─────────────────────────────────────────╮${NC}"
    
    # Lines with 1 space padding: │ content │
    local single_pad_width=$((total_content_width - 0))  # 59 chars
    printf "${CYAN}│${NC} %-${single_pad_width}s ${CYAN}│${NC}\n" "Would you like to automatically configure your shell?"
    printf "${CYAN}│${NC} %-${single_pad_width}s ${CYAN}│${NC}\n" "This will add the following lines to your shell config:"
    printf "${CYAN}│${NC} %-${single_pad_width}s ${CYAN}│${NC}\n" ""
    
    # Handle shell config file display with 1 space padding
    local config_line="File: $shell_config"
    if [ ${#config_line} -gt $single_pad_width ]; then
        local max_path_length=$((single_pad_width - 9))  # "File: ..." = 9 chars
        config_line="File: ...${shell_config: -$max_path_length}"
    fi
    printf "${CYAN}│${NC} ${WHITE}%s${NC}%*s ${CYAN}│${NC}\n" "$config_line" $((single_pad_width - ${#config_line})) ""
    printf "${CYAN}│${NC} %-${single_pad_width}s ${CYAN}│${NC}\n" ""
    
    # Lines with 3 space indent: │   content │
    local triple_indent_width=$((total_content_width - 2))  # 57 chars (3 spaces + 1 space padding)
    
    # Handle comment line with 3 space indent
    local comment_line="# Azure CLI Profile Manager"
    printf "${CYAN}│${NC}   ${YELLOW}%s${NC}%*s ${CYAN}│${NC}\n" "$comment_line" $((triple_indent_width - ${#comment_line})) ""
    
    # Handle export PATH line with 3 space indent
    local export_line="export PATH=\"$INSTALL_DIR:\$PATH\""
    if [ ${#export_line} -gt $triple_indent_width ]; then
        local max_install_length=$((triple_indent_width - 20))  # "export PATH=\"...:\$PATH\"" = 20 chars
        export_line="export PATH=\"...${INSTALL_DIR: -$max_install_length}:\$PATH\""
    fi
    printf "${CYAN}│${NC}   ${YELLOW}%s${NC}%*s ${CYAN}│${NC}\n" "$export_line" $((triple_indent_width - ${#export_line})) ""
    
    # Handle source line with 3 space indent
    local source_line="source $CONFIG_DIR/az-profile-helpers.sh"
    if [ ${#source_line} -gt $triple_indent_width ]; then
        local max_config_length=$((triple_indent_width - 32))  # "source .../az-profile-helpers.sh" = 32 chars
        source_line="source ...${CONFIG_DIR: -$max_config_length}/az-profile-helpers.sh"
    fi
    printf "${CYAN}│${NC}   ${YELLOW}%s${NC}%*s ${CYAN}│${NC}\n" "$source_line" $((triple_indent_width - ${#source_line})) ""
    
    echo -e "${CYAN}╰───────────────────────────────────────────────────────────────╯${NC}"
    echo ""
    echo -e "${WHITE}💡 This is recommended for the best experience!${NC}"
    echo -e "${WHITE}📝 Your original config will be backed up automatically.${NC}"
    echo ""
    echo -e "${GREEN}Press Enter to accept [Y] or type 'n' for No:${NC}"
    
    local response=$(prompt_user "Configure shell automatically?" "y")
    
    if [[ "$response" =~ ^[Yy]$ ]] || [[ -z "$response" ]]; then
        # Backup existing config
        cp "$shell_config" "${shell_config}.backup.$(date +%Y%m%d_%H%M%S)"
        
        # Add configuration
        cat >> "$shell_config" << EOF

# Azure CLI Profile Manager
export PATH="$INSTALL_DIR:\$PATH"
source "$CONFIG_DIR/az-profile-helpers.sh"
EOF
        
        log_success "Shell configuration updated!"
        log_info "Backup created: ${shell_config}.backup.$(date +%Y%m%d_%H%M%S)"
    else
        log_info "Skipping automatic shell configuration."
        log_warning "Don't forget to manually add the following to your shell config:"
        echo -e "${YELLOW}  export PATH=\"$INSTALL_DIR:\$PATH\"${NC}"
        echo -e "${YELLOW}  source $CONFIG_DIR/az-profile-helpers.sh${NC}"
    fi
    
    echo ""
}


setup_examples() {
    if [ -d "$CONFIG_DIR/examples" ]; then
        log_step "Setting up example profiles..."
        
        echo -e "${CYAN}Example profile configurations are available at:${NC}"
        echo -e "${YELLOW}  $CONFIG_DIR/examples/${NC}"
        echo ""
        echo "You can use these as templates for your own profiles:"
        
        for example in "$CONFIG_DIR/examples"/*.profile; do
            if [ -f "$example" ]; then
                local basename_file=$(basename "$example")
                echo -e "  ${GREEN}$basename_file${NC}"
            fi
        done
        echo ""
    fi
}

run_post_install_checks() {
    log_step "Running post-installation checks..."
    
    # Check if az-profile is in PATH
    local az_profile_path=$(which az-profile 2>/dev/null || echo "")
    if [ -n "$az_profile_path" ]; then
        log_success "az-profile is available in PATH: $az_profile_path"
    else
        log_warning "az-profile not found in PATH. You may need to restart your shell."
    fi
    
    # Test basic functionality
    if [ -x "$INSTALL_DIR/az-profile" ]; then
        local version_output=$("$INSTALL_DIR/az-profile" --help | head -1)
        log_success "Installation test passed!"
    else
        log_error "Installation test failed - az-profile is not executable"
    fi
    
    echo ""
}

show_getting_started() {
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${WHITE}                    🎉 Installation Complete! 🎉                ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}📍 Installation Summary:${NC}"
    echo -e "   • Executable: ${YELLOW}$INSTALL_DIR/az-profile${NC}"
    echo -e "   • Config Dir: ${YELLOW}$CONFIG_DIR${NC}"
    echo -e "   • Profiles:   ${YELLOW}$PROFILES_DIR${NC}"
    echo ""
    echo -e "${CYAN}🚀 Quick Start:${NC}"
    echo -e "   1. ${WHITE}Restart your shell${NC} or run: ${YELLOW}source ~/.bashrc${NC}"
    echo -e "   2. ${WHITE}Create your first profile:${NC}"
    echo -e "      ${YELLOW}az-profile create mycompany --type server --org https://devops.company.com${NC}"
    echo -e "   3. ${WHITE}Activate it:${NC}"
    echo -e "      ${YELLOW}azp mycompany${NC}"
    echo -e "   4. ${WHITE}Start using Azure CLI${NC} with your new profile!"
    echo ""
    echo -e "${CYAN}📚 Learn More:${NC}"
    echo -e "   • ${WHITE}Get help:${NC}        ${YELLOW}az-profile help${NC}"
    echo -e "   • ${WHITE}Helper functions:${NC} ${YELLOW}azp-help${NC}"
    echo -e "   • ${WHITE}List profiles:${NC}   ${YELLOW}azp${NC}"
    echo -e "   • ${WHITE}Check status:${NC}    ${YELLOW}azp status${NC}"
    echo ""
    echo -e "${CYAN}💡 Pro Tips:${NC}"
    echo -e "   • Use ${YELLOW}azp${NC} for quick profile switching"
    echo -e "   • Try ${YELLOW}az-profile create --profile-url <git-repo> --batch${NC} for team setups"
    echo -e "   • Check out examples in ${YELLOW}$CONFIG_DIR/examples/${NC}"
    echo ""
    echo -e "${GREEN}Happy Azure profiling! 🌟${NC}"
    echo ""
}

cleanup_on_error() {
    log_error "Installation failed. Cleaning up..."
    rm -f "$INSTALL_DIR/az-profile" 2>/dev/null
    rm -rf "$CONFIG_DIR" 2>/dev/null
    exit 1
}

# Parse command line arguments
INSTALL_DIR="$DEFAULT_INSTALL_DIR"
CONFIG_DIR="$DEFAULT_CONFIG_DIR"
INSTALL_FROM_LOCAL=""
QUIET_MODE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --install-dir)
            INSTALL_DIR="$2"
            shift 2
            ;;
        --config-dir)
            CONFIG_DIR="$2"
            shift 2
            ;;
        --local)
            INSTALL_FROM_LOCAL="$2"
            shift 2
            ;;
        --quiet|-q)
            QUIET_MODE="true"
            shift
            ;;
        --help|-h)
            cat << EOF
Azure CLI Profile Manager - Installation Script

Usage: $0 [OPTIONS]

Options:
  --install-dir DIR    Directory to install az-profile executable (default: $DEFAULT_INSTALL_DIR)
  --config-dir DIR     Directory for configuration files (default: $DEFAULT_CONFIG_DIR)
  --local DIR          Install from local directory instead of git repository
  --quiet, -q          Quiet mode - minimal output
  --help, -h           Show this help message

Examples:
  $0                                    # Install with defaults
  $0 --install-dir /usr/local/bin       # Install system-wide
  $0 --local /path/to/az-profile-cli    # Install from local directory
  $0 --quiet                           # Quiet installation

EOF
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            log_info "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Main installation flow
trap cleanup_on_error ERR

if [ -z "$QUIET_MODE" ]; then
    print_banner
fi

check_prerequisites
install_files

if [ -z "$QUIET_MODE" ]; then
    setup_shell_integration
    setup_examples
fi

run_post_install_checks

if [ -z "$QUIET_MODE" ]; then
    show_getting_started
else
    log_success "Azure CLI Profile Manager installed successfully!"
    echo "Restart your shell and run 'az-profile help' to get started."
fi

exit 0
