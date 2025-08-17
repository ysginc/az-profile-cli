#!/bin/bash

# Azure CLI Profile Helper Functions
# Source this file in your ~/.bashrc or ~/.zshrc for convenient functions
#
# Usage: source ./az-profile-helpers.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AZ_PROFILE_SCRIPT="az-profile"

# Quick activate function
azp() {
    if [ $# -eq 0 ]; then
        "$AZ_PROFILE_SCRIPT" list
        return
    fi
    
    case "$1" in
        "list"|"ls")
            "$AZ_PROFILE_SCRIPT" list
            ;;
        "status"|"current")
            "$AZ_PROFILE_SCRIPT" status
            ;;
        "deactivate"|"off")
            "$AZ_PROFILE_SCRIPT" deactivate
            ;;
        *)
            # Try to activate the profile
            # Use same logic as main script for profile directory
            if [ -n "$AZ_PROFILE_DIR" ]; then
                profiles_dir="$AZ_PROFILE_DIR"
            else
                profiles_dir="$HOME/.az-profiles"
            fi
            
            profile_path="$profiles_dir/$1"
            if [ -d "$profile_path" ]; then
                export AZURE_CONFIG_DIR="$profile_path"
                echo "$1" > "$profiles_dir/.active-profile"
                echo "✓ Activated Azure CLI profile: $1"
                echo "  Config directory: $profile_path"
                
                # Show current context if az is available
                if command -v az >/dev/null 2>&1; then
                    echo "  Azure context:"
                    az account show --query "{name:name, id:id}" -o tsv 2>/dev/null | while read -r name id; do
                        echo "    Account: $name ($id)"
                    done || echo "    Not logged in"
                fi
            else
                echo "Error: Profile '$1' does not exist"
                echo "Available profiles:"
                "$AZ_PROFILE_SCRIPT" list
            fi
            ;;
    esac
}

# Deactivate profile
azp-off() {
    "$AZ_PROFILE_SCRIPT" deactivate
    unset AZURE_CONFIG_DIR
}

# List profiles
azp-list() {
    "$AZ_PROFILE_SCRIPT" list
}

# Show status
azp-status() {
    "$AZ_PROFILE_SCRIPT" status
}

# Create profile
azp-create() {
    "$AZ_PROFILE_SCRIPT" create "$1"
}

# Delete profile
azp-delete() {
    "$AZ_PROFILE_SCRIPT" delete "$1"
}

# Login to profile (deprecated - use azp-devops-login)
azp-login() {
    echo "Warning: azp-login is deprecated. Use azp-devops-login instead." >&2
    "$AZ_PROFILE_SCRIPT" devops login "$1"
}

# Configure profile (deprecated - use azp-devops-configure)
azp-configure() {
    echo "Warning: azp-configure is deprecated. Use azp-devops-configure instead." >&2
    "$AZ_PROFILE_SCRIPT" devops configure "$1"
}

# Run command with profile (deprecated - use azp-devops-run)
azp-run() {
    echo "Warning: azp-run is deprecated. Use azp-devops-run instead." >&2
    "$AZ_PROFILE_SCRIPT" devops run "$@"
}

# DevOps login to profile
azp-devops-login() {
    "$AZ_PROFILE_SCRIPT" devops login "$@"
}

# DevOps configure profile
azp-devops-configure() {
    "$AZ_PROFILE_SCRIPT" devops configure "$@"
}

# DevOps run command with profile
azp-devops-run() {
    "$AZ_PROFILE_SCRIPT" devops run "$@"
}

# DevOps help
azp-devops-help() {
    "$AZ_PROFILE_SCRIPT" devops help
}

# az-profile function that intercepts calls to handle activation in current shell
az-profile() {
    # Path to the actual az-profile script
    local az_profile_script
    if command -v "$(dirname "${BASH_SOURCE[0]}")/az-profile" >/dev/null 2>&1; then
        az_profile_script="$(dirname "${BASH_SOURCE[0]}")/az-profile"
    else
        az_profile_script="$(command -v az-profile 2>/dev/null || echo "az-profile")"
    fi
    
    # Handle activation and deactivation in current shell
    case "${1:-}" in
        "activate")
            if [ -z "$2" ]; then
                echo "Error: Profile name is required" >&2
                echo "Usage: az-profile activate <profile_name>" >&2
                return 1
            fi
            
            local profile_name="$2"
            # Use same logic as main script for profile directory
            local profiles_dir
            if [ -n "$AZ_PROFILE_DIR" ]; then
                profiles_dir="$AZ_PROFILE_DIR"
            else
                profiles_dir="$HOME/.az-profiles"
            fi
            
            local profile_path="$profiles_dir/$profile_name"
            if [ ! -d "$profile_path" ]; then
                echo -e "\033[0;31m[ERROR]\033[0m Profile '$profile_name' does not exist" >&2
                echo "Available profiles:" >&2
                "$az_profile_script" list >&2
                return 1
            fi
            
            # Set active profile and export environment variable
            mkdir -p "$profiles_dir"
            echo "$profile_name" > "$profiles_dir/.active-profile"
            export AZURE_CONFIG_DIR="$profile_path"
            
            # Success messages
            echo -e "\033[0;32m[SUCCESS]\033[0m Activated profile '$profile_name'"
            echo -e "\033[0;34m[INFO]\033[0m Azure config directory: $profile_path"
            echo -e "\033[0;34m[INFO]\033[0m Environment variable set for current shell session"
            
            # Show current Azure context if available
            if command -v az >/dev/null 2>&1; then
                echo ""
                echo -e "\033[0;34m[INFO]\033[0m Current Azure context:"
                AZURE_CONFIG_DIR="$profile_path" az account show --query "{name:name, id:id, tenantId:tenantId}" -o table 2>/dev/null || echo "  Not logged in"
            fi
            ;;
        
        "deactivate")
            local profiles_dir
            if [ -n "$AZ_PROFILE_DIR" ]; then
                profiles_dir="$AZ_PROFILE_DIR"
            else
                profiles_dir="$HOME/.az-profiles"
            fi
            
            if [ -f "$profiles_dir/.active-profile" ]; then
                local current_profile
                current_profile=$(cat "$profiles_dir/.active-profile")
                rm -f "$profiles_dir/.active-profile"
                unset AZURE_CONFIG_DIR
                echo -e "\033[0;32m[SUCCESS]\033[0m Deactivated profile '$current_profile'"
                echo -e "\033[0;34m[INFO]\033[0m Azure CLI will use default configuration"
            else
                echo -e "\033[0;34m[INFO]\033[0m No active profile to deactivate"
            fi
            ;;
        
        *)
            # For all other commands, delegate to the actual script
            "$az_profile_script" "$@"
            ;;
    esac
}

# Show help for helper functions
azp-help() {
    cat << 'EOF'
Azure CLI Profile Helper Functions

Main Commands (with shell session integration):
  az-profile <cmd>        Full az-profile with shell integration
  az-profile activate <profile>   Activate profile in current shell
  az-profile deactivate           Deactivate current profile
  az-profile <any-other-cmd>      Delegates to actual az-profile script

Quick Commands:
  azp                     List all profiles
  azp <profile>           Activate a profile
  azp list               List all profiles
  azp status             Show current profile status
  azp deactivate         Deactivate current profile

Profile Management:
  azp-list               List all profiles
  azp-status             Show current profile status
  azp-off                Deactivate current profile
  azp-create <name>      Create a new profile
  azp-delete <name>      Delete a profile

DevOps Commands (New):
  azp-devops-login <profile> [options]     Login to DevOps with profile
  azp-devops-configure <profile> [options] Configure DevOps settings for profile
  azp-devops-run <profile> <command>       Run DevOps command with profile
  azp-devops-help                          Show DevOps command help

Legacy DevOps Commands (Deprecated):
  azp-login <name>       Login to a profile (use azp-devops-login)
  azp-configure <name>   Configure DevOps settings (use azp-devops-configure)
  azp-run <name> <cmd>   Run command with profile (use azp-devops-run)

Examples:
  # Profile activation:
  azp myorg                              # Quick activate myorg profile
  az-profile activate myorg              # Full command activate myorg profile
  
  # Profile management:
  azp-create mycompany                   # Create mycompany profile
  azp-delete oldprofile                  # Delete oldprofile
  
  # DevOps operations (new commands):
  azp-devops-login myorg                 # Login to DevOps with myorg profile
  azp-devops-configure myorg --org https://dev.azure.com/myorg
  azp-devops-run myorg project list      # Run DevOps command with myorg profile
  azp-devops-help                        # Show DevOps help
  
  # Full command equivalents:
  az-profile devops login myorg          # Same as azp-devops-login myorg
  az-profile devops run myorg project list  # Same as azp-devops-run

For full help: ./az-profile help
For DevOps help: azp-devops-help or ./az-profile devops help
EOF
}

echo "Azure CLI Profile helpers loaded!"
echo "Type 'azp-help' for usage information"
echo "Type 'azp' to list profiles or 'azp <profile>' to activate"
