#!/bin/bash

# Azure CLI Profile Manager - Uninstall Script
# Safely removes all az-profile-cli components while preserving your profiles! 🧹

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

# Configuration - match install.sh defaults
DEFAULT_INSTALL_DIR="$HOME/.local/bin"
DEFAULT_CONFIG_DIR="$HOME/.config/az-profile-cli"
DEFAULT_REPO_DIR="$HOME/.local/share/az-profile-cli"
PROFILES_DIR="$HOME/.az-profiles"

# Helper functions
print_banner() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}          🧹 Azure CLI Profile Manager Uninstaller            ${CYAN}║${NC}"
    echo -e "${CYAN}║                                                              ║${NC}"
    echo -e "${CYAN}║${YELLOW}       Cleaning up your system safely and thoroughly!       ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

log_info() {
    if [ "$QUIET_MODE" != "true" ]; then
        echo -e "${BLUE}[INFO]${NC} $1"
    fi
}

log_success() {
    if [ "$QUIET_MODE" != "true" ]; then
        echo -e "${GREEN}[SUCCESS]${NC} $1"
    fi
}

log_warning() {
    if [ "$QUIET_MODE" != "true" ]; then
        echo -e "${YELLOW}[WARNING]${NC} $1"
    fi
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    if [ "$QUIET_MODE" != "true" ]; then
        echo -e "${PURPLE}[STEP]${NC} $1"
    fi
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

detect_shell_configs() {
    local configs=()
    
    # Common shell configuration files
    [ -f "$HOME/.bashrc" ] && configs+=("$HOME/.bashrc")
    [ -f "$HOME/.bash_profile" ] && configs+=("$HOME/.bash_profile")
    [ -f "$HOME/.zshrc" ] && configs+=("$HOME/.zshrc")
    [ -f "$HOME/.config/fish/config.fish" ] && configs+=("$HOME/.config/fish/config.fish")
    
    printf '%s\n' "${configs[@]}"
}

show_removal_summary() {
    log_step "Analyzing current installation..."
    echo ""
    
    local found_items=()
    local shell_configs_with_integration=()
    
    # Check executable
    if [ -f "$INSTALL_DIR/az-profile" ]; then
        found_items+=("Executable: $INSTALL_DIR/az-profile")
    fi
    
    # Check config directory
    if [ -d "$CONFIG_DIR" ]; then
        found_items+=("Configuration: $CONFIG_DIR")
    fi
    
    # Check repository directory
    if [ -d "$DEFAULT_REPO_DIR" ]; then
        found_items+=("Repository: $DEFAULT_REPO_DIR")
    fi
    
    # Check shell integrations
    while IFS= read -r config; do
        if grep -q "az-profile-helpers.sh" "$config" 2>/dev/null; then
            shell_configs_with_integration+=("$config")
            found_items+=("Shell integration: $config")
        fi
    done < <(detect_shell_configs)
    
    # Check if profiles exist
    local profile_count=0
    if [ -d "$PROFILES_DIR" ]; then
        profile_count=$(find "$PROFILES_DIR" -name "*.profile" -type f 2>/dev/null | wc -l)
    fi
    
    if [ ${#found_items[@]} -eq 0 ]; then
        echo -e "${GREEN}✨ No az-profile-cli components found on your system!${NC}"
        echo ""
        if [ $profile_count -gt 0 ]; then
            echo -e "${CYAN}📂 Your profiles are still preserved:${NC}"
            echo -e "   • Profile directory: ${YELLOW}$PROFILES_DIR${NC}"
            echo -e "   • Profile count: ${YELLOW}$profile_count${NC}"
        fi
        return 1
    fi
    
    echo -e "${CYAN}🔍 Found the following components to remove:${NC}"
    for item in "${found_items[@]}"; do
        echo -e "   • ${YELLOW}$item${NC}"
    done
    echo ""
    
    if [ $profile_count -gt 0 ]; then
        echo -e "${GREEN}✅ Your profiles will be preserved:${NC}"
        echo -e "   • Profile directory: ${YELLOW}$PROFILES_DIR${NC}"
        echo -e "   • Profile count: ${YELLOW}$profile_count${NC}"
        echo ""
    fi
    
    return 0
}

remove_executable() {
    if [ -f "$INSTALL_DIR/az-profile" ]; then
        log_step "Removing executable..."
        rm -f "$INSTALL_DIR/az-profile"
        log_success "Removed: $INSTALL_DIR/az-profile"
    fi
}

remove_configuration() {
    if [ -d "$CONFIG_DIR" ]; then
        log_step "Removing configuration directory..."
        rm -rf "$CONFIG_DIR"
        log_success "Removed: $CONFIG_DIR"
    fi
}

remove_repository() {
    if [ -d "$DEFAULT_REPO_DIR" ]; then
        log_step "Removing repository directory..."
        rm -rf "$DEFAULT_REPO_DIR"
        log_success "Removed: $DEFAULT_REPO_DIR"
    fi
}

remove_shell_integration() {
    log_step "Removing shell integrations..."
    
    local configs_modified=0
    
    while IFS= read -r config; do
        if [ -f "$config" ] && grep -q "az-profile-helpers.sh" "$config" 2>/dev/null; then
            log_info "Processing: $config"
            
            # Create backup
            cp "$config" "${config}.backup.uninstall.$(date +%Y%m%d_%H%M%S)"
            
            # Remove az-profile related lines
            # This removes the comment line and the two configuration lines
            sed -i '/# Azure CLI Profile Manager/d' "$config"
            sed -i '\|az-profile-helpers.sh|d' "$config"
            sed -i '\|/.local/bin.*az-profile|d' "$config"
            
            # Remove any export PATH lines that include our install directory
            sed -i "\|export PATH.*$INSTALL_DIR|d" "$config"
            
            log_success "Updated: $config"
            log_info "Backup created: ${config}.backup.uninstall.$(date +%Y%m%d_%H%M%S)"
            configs_modified=$((configs_modified + 1))
        fi
    done < <(detect_shell_configs)
    
    if [ $configs_modified -eq 0 ]; then
        log_info "No shell integration found to remove"
    elif [ "$QUIET_MODE" != "true" ]; then
        echo ""
        log_warning "Shell configuration updated. You may need to:"
        echo -e "   • Restart your shell or run: ${YELLOW}source ~/.bashrc${NC}"
        echo -e "   • Remove any remaining PATH modifications manually if needed"
    fi
}

check_environment() {
    log_step "Checking active environment..."
    
    local warnings=()
    
    # Check if az-profile is still in PATH
    if command -v az-profile >/dev/null 2>&1; then
        warnings+=("az-profile is still available in your PATH")
    fi
    
    # Check for active profile
    if [ -n "$AZURE_CONFIG_DIR" ] && [ -d "$AZURE_CONFIG_DIR" ]; then
        warnings+=("Active Azure profile detected: $AZURE_CONFIG_DIR")
    fi
    
    # Check for azp function
    if declare -f azp >/dev/null 2>&1; then
        warnings+=("azp shell function is still loaded")
    fi
    
    if [ ${#warnings[@]} -gt 0 ]; then
        log_warning "Environment cleanup needed:"
        for warning in "${warnings[@]}"; do
            echo -e "   • ${YELLOW}$warning${NC}"
        done
        echo ""
        echo -e "${WHITE}💡 To complete cleanup:${NC}"
        echo -e "   1. Restart your shell or run: ${YELLOW}source ~/.bashrc${NC}"
        echo -e "   2. Unset AZURE_CONFIG_DIR if needed: ${YELLOW}unset AZURE_CONFIG_DIR${NC}"
    else
        log_success "Environment is clean!"
    fi
}

show_completion() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${WHITE}                    🎉 Uninstall Complete! 🎉                 ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}📋 What was removed:${NC}"
    echo -e "   • az-profile executable and configuration"
    echo -e "   • Shell integration and PATH modifications" 
    echo -e "   • Repository cache (if present)"
    echo ""
    echo -e "${CYAN}💾 What was preserved:${NC}"
    echo -e "   • Your Azure CLI profiles: ${YELLOW}$PROFILES_DIR${NC}"
    echo -e "   • Shell configuration backups (*.backup.uninstall.*)"
    echo ""
    echo -e "${CYAN}🔧 Next steps:${NC}"
    echo -e "   • Restart your shell for changes to take effect"
    echo -e "   • Your Azure CLI profiles can still be used manually"
    echo -e "   • Backups are available if you need to restore anything"
    echo ""
    echo -e "${WHITE}Thanks for using Azure CLI Profile Manager! 🙏${NC}"
    echo ""
}

# Parse command line arguments
INSTALL_DIR="$DEFAULT_INSTALL_DIR"
CONFIG_DIR="$DEFAULT_CONFIG_DIR"
FORCE_REMOVE="false"
QUIET_MODE="false"

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
        --force|-f)
            FORCE_REMOVE="true"
            shift
            ;;
        --quiet|-q)
            QUIET_MODE="true"
            shift
            ;;
        --help|-h)
            cat << EOF
Azure CLI Profile Manager - Uninstall Script

Usage: $0 [OPTIONS]

Options:
  --install-dir DIR    Directory where az-profile executable is installed (default: $DEFAULT_INSTALL_DIR)
  --config-dir DIR     Directory where configuration files are stored (default: $DEFAULT_CONFIG_DIR)
  --force, -f          Force removal without confirmation prompts
  --quiet, -q          Quiet mode - minimal output
  --help, -h           Show this help message

Examples:
  $0                                    # Interactive uninstall
  $0 --force                           # Uninstall without prompts
  $0 --install-dir /usr/local/bin      # Uninstall from custom location
  $0 --quiet --force                   # Silent uninstall

Note: Your Azure CLI profiles in $PROFILES_DIR will be preserved.

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

# Main uninstall flow
if [ "$QUIET_MODE" != "true" ]; then
    print_banner
fi

# Check what's installed (skip in quiet mode)
if [ "$QUIET_MODE" != "true" ]; then
    if ! show_removal_summary; then
        exit 0
    fi
fi

# Get user confirmation unless forced or in quiet mode
if [ "$FORCE_REMOVE" != "true" ] && [ "$QUIET_MODE" != "true" ]; then
    echo -e "${CYAN}⚠️  This will remove all az-profile-cli components from your system.${NC}"
    echo -e "${GREEN}✅ Your Azure CLI profiles will be preserved.${NC}"
    echo ""
    
    response=$(prompt_user "Continue with uninstall?" "y")
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        log_info "Uninstall cancelled by user."
        exit 0
    fi
    echo ""
fi

# Perform removal
remove_executable
remove_configuration
remove_repository
remove_shell_integration

if [ "$QUIET_MODE" != "true" ]; then
    echo ""
    check_environment
    show_completion
else
    log_success "Azure CLI Profile Manager uninstalled successfully!"
fi

exit 0
