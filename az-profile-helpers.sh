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

# Show help for helper functions
azp-help() {
    cat << 'EOF'
Azure CLI Profile Helper Functions

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
  azp myorg                          # Activate myorg profile
  azp-create mycompany               # Create mycompany profile
  azp-login mycompany                # Login to mycompany profile
  azp-configure mycompany            # Configure mycompany profile
  azp-run myorg devops project list  # Run command with myorg profile

For full help: ./az-profile help
EOF
}

echo "Azure CLI Profile helpers loaded!"
echo "Type 'azp-help' for usage information"
echo "Type 'azp' to list profiles or 'azp <profile>' to activate"
