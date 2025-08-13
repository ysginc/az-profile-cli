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

# Login to profile
azp-login() {
    "$AZ_PROFILE_SCRIPT" login "$1"
}

# Configure profile
azp-configure() {
    "$AZ_PROFILE_SCRIPT" configure "$1"
}

# Run command with profile
azp-run() {
    "$AZ_PROFILE_SCRIPT" run "$@"
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

Full Commands:
  azp-list               List all profiles
  azp-status             Show current profile status
  azp-off                Deactivate current profile
  azp-create <name>      Create a new profile
  azp-delete <name>      Delete a profile
  azp-login <name>       Login to a profile
  azp-configure <name>   Configure DevOps settings for a profile
  azp-run <name> <cmd>   Run az command with specific profile

Examples:
  # Activation (both work the same in interactive shells):
  azp myorg                          # Quick activate myorg profile
  az-profile activate myorg          # Full command activate myorg profile
  
  # Other commands:
  azp-create mycompany               # Create mycompany profile
  az-profile create mycompany        # Same as above (delegates to script)
  azp-login mycompany                # Login to mycompany profile
  az-profile login mycompany         # Same as above (delegates to script)
  az-profile run myorg devops project list  # Run command with myorg profile

For full help: ./az-profile help
EOF
}

echo "Azure CLI Profile helpers loaded!"
echo "Type 'azp-help' for usage information"
echo "Type 'azp' to list profiles or 'azp <profile>' to activate"
