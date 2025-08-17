# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Azure CLI Profile Manager is a Bash-based tool for managing multiple Azure CLI profiles, allowing users to switch between different Azure environments, subscriptions, and DevOps organizations seamlessly. The tool supports both Azure Cloud and on-premises Azure DevOps Server configurations.

## Development Commands

### Installation and Setup
- `./install.sh` - Install the tool system-wide (creates symlinks to ~/.local/bin)
- `./uninstall.sh` - Remove the tool and clean up installations
- `chmod +x az-profile` - Make the main script executable (if needed)

### Testing and Usage
- `./az-profile help` - Show usage information and available commands
- `./az-profile list` - List all configured profiles
- `./az-profile create <name> [options]` - Create a new profile
- `./az-profile activate <name>` - Activate a profile
- `./az-profile status` - Show current active profile status

### Helper Functions
- `source ./az-profile-helpers.sh` - Load convenience functions into shell
- After sourcing: `azp` (list profiles), `azp <name>` (activate), `azp-help` (show helper usage)

## Architecture and File Structure

### Core Components
- **`az-profile`** - Main executable script (1400+ lines of Bash)
- **`az-profile-helpers.sh`** - Shell helper functions for convenient usage
- **`install.sh`** - Installation script with user interaction
- **`uninstall.sh`** - Clean removal script
- **`examples/`** - Sample profile configuration files (*.profile format)

### Profile Management System
- Profiles stored in `~/.az-profiles/` by default (configurable via `$AZ_PROFILE_DIR`)
- Each profile has its own directory containing Azure CLI configuration
- Active profile tracked in `~/.az-profiles/.active-profile`
- Profile activation sets `AZURE_CONFIG_DIR` environment variable

### Configuration File Format
Profiles can be created from `.profile` files with INI-style sections:
- `[profile]` - Basic profile metadata (name, type, description)
- `[azure]` - Azure cloud configuration (AzureCloud, AzureUSGovernment, etc.)
- `[devops]` - DevOps organization settings
- `[auth]` - Authentication method configuration (pat, azure-ad, interactive)
- `[defaults]` - Default project and other settings

### Authentication Methods
- **PAT (Personal Access Token)** - For server environments
- **Azure AD** - Standard cloud authentication
- **Interactive** - Manual login prompts

## Key Implementation Details

### Profile Creation Sources
1. Manual creation with command-line parameters
2. Local `.profile` configuration files
3. Remote `.profile` files via HTTP/HTTPS
4. Git repositories containing multiple profiles (supports batch import)

### Environment Integration
- Shell helper functions provide `azp` shortcuts for common operations
- Profile activation persists `AZURE_CONFIG_DIR` in current shell session
- Installation script can automatically configure shell RC files
- Update mechanism for git-based installations

### Error Handling and Validation
- Profile names restricted to alphanumeric, hyphens, and underscores
- Credential resolution supports file paths, environment variables, and direct values
- Comprehensive logging with colored output (INFO, SUCCESS, WARNING, ERROR)
- Automatic backup of shell configuration files during installation

## Development Guidelines

### Code Conventions
- Bash script follows strict error handling (`set -e`)
- Consistent color-coded logging functions
- Extensive parameter validation and user-friendly error messages
- Comprehensive help documentation built into commands

### Configuration Management
- Default directories follow XDG-style conventions (`~/.local/`, `~/.config/`)
- Environment variable overrides for all major paths
- Profile isolation through separate Azure CLI config directories

### Dependencies
- **Required**: bash, git, curl/wget
- **Optional but recommended**: Azure CLI (`az` command)
- No external package managers or build systems required