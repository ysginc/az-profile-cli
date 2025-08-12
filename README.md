# 🚀 Azure CLI Profile Manager
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) [![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25.svg)](https://www.gnu.org/software/bash/) [![Azure CLI](https://img.shields.io/badge/Azure-CLI-0078D4.svg)](https://docs.microsoft.com/en-us/cli/azure/)

> **Because juggling multiple Azure environments shouldn't feel like a circus act! 🎪**

Ever found yourself frantically switching between different Azure subscriptions, DevOps organizations, and cloud environments? Tired of accidentally deploying your test code to production because you forgot to switch contexts? **We've got you covered!** 

This tool makes managing multiple Azure CLI profiles as easy as changing TV channels (but way more useful).

## 📸 What's This All About?

The Azure CLI Profile Manager is a powerful Bash script that lets you:

- 🔀 **Switch between Azure environments instantly**
- 🏢 **Manage multiple organizations** (cloud and on-premises)
- 🔐 **Handle different authentication methods** seamlessly
- 📦 **Import profiles from Git repositories** (because sharing is caring)
- ⚡ **Batch create multiple profiles** at once
- 🎯 **Never accidentally work in the wrong environment again**

Think of it as your personal Azure environment butler - always ready to serve up the right context at the right time! 🧐

## 🎬 Quick Demo

```bash
# List all your profiles (like checking your wardrobe)
./az-profile list

# Create a new profile (tailored to perfection)
./az-profile create mycompany --type server --org https://devops.company.com

# Switch contexts faster than a chameleon changes colors
./az-profile activate mycompany

# Run a command with a specific profile (no switching required)
./az-profile run mycompany devops project list

# Import an entire wardrobe of profiles from Git
./az-profile create --profile-url https://github.com/company/az-profiles.git --batch
```

## 🛠️ Installation

### Option 1: The "I Trust You Completely" Method
```bash
curl -fsSL https://raw.githubusercontent.com/ysginc/az-profile-cli/main/install.sh | bash
```

### Option 2: The "I Like to See What I'm Running" Method
```bash
git clone https://github.com/ysginc/az-profile-cli.git
cd az-profile-cli
chmod +x az-profile
```

### Option 3: The "I Want Maximum Convenience" Method
```bash
git clone https://github.com/ysginc/az-profile-cli.git
cd az-profile-cli
chmod +x az-profile

# Add helper functions to your shell (recommended!)
echo "source $(pwd)/az-profile-helpers.sh" >> ~/.bashrc
source ~/.bashrc
```

## 🎮 Usage Guide

### Basic Commands (The Essentials)

| Command | What It Does | Example |
|---------|--------------|---------|
| `list` | Shows all your profiles | `./az-profile list` |
| `create` | Makes a new profile | `./az-profile create work` |
| `activate` | Switches to a profile | `./az-profile activate work` |
| `deactivate` | Goes back to default | `./az-profile deactivate` |
| `status` | Shows current profile | `./az-profile status` |
| `delete` | Removes a profile | `./az-profile delete old-work` |

### Advanced Commands (The Power Moves)

| Command | What It Does | Example |
|---------|--------------|---------|
| `login` | Authenticate for a profile | `./az-profile login work` |
| `configure` | Set up DevOps defaults | `./az-profile configure work` |
| `run` | Execute with specific profile | `./az-profile run work devops project list` |

### Profile Creation (The Fun Stuff)

#### 🏢 Manual Profile Creation
```bash
# Basic server profile
./az-profile create mycompany --type server \
  --org https://devops.company.com/DefaultCollection \
  --pat-file ./my-secret-token

# Cloud profile with specific Azure government
./az-profile create govcloud --type cloud \
  --org https://dev.azure.us/myorg \
  --cloud AzureUSGovernment
```

#### 📁 Profile From Configuration File
```bash
# Use a local .profile file
./az-profile create myprofile --profile-file ./configs/company.profile

# Download from URL
./az-profile create myprofile --profile-url https://example.com/profiles/company.profile
```

#### 🎯 Git Repository Magic
```bash
# Clone repo and pick interactively
./az-profile create myprofile --profile-url https://github.com/company/az-profiles.git

# Select specific profile by name
./az-profile create myprofile --profile-url https://github.com/company/az-profiles.git --profile-name production

# Import ALL profiles (batch mode)
./az-profile create --profile-url https://github.com/company/az-profiles.git --batch
```

## 📝 Profile Configuration Files

Create reusable profile configurations that you can share with your team! Here's what a `.profile` file looks like:

```ini
# company.profile - Because sharing configs is caring!
[profile]
name=company-prod
type=server
description=Company Production Azure DevOps Server

[azure]
# Specify Azure cloud (optional)
cloud=AzureCloud

[devops]
organization=https://devops.company.com/DefaultCollection

[auth]
# Authentication method: pat, azure-ad, interactive
method=pat
# PAT token sources (flexible options)
pat_file=./tokens/company-prod.pat
# Alternative: pat_env=COMPANY_PROD_PAT
# Alternative: pat=your-direct-token

[defaults]
# Set default project (optional)
project=MainProject
```

### 🔐 Authentication Options

The tool supports multiple authentication methods:

| Method | Description | Configuration |
|--------|-------------|---------------|
| `pat` | Personal Access Token | `pat_file=./token.txt` or `pat_env=MY_TOKEN` |
| `azure-ad` | Azure Active Directory | `method=azure-ad` |
| `interactive` | Interactive login | `method=interactive` |

### 🌍 Supported Azure Clouds

| Cloud | Usage |
|-------|-------|
| Azure Commercial | `cloud=AzureCloud` |
| Azure Government | `cloud=AzureUSGovernment` |
| Azure China | `cloud=AzureChinaCloud` |
| Azure Germany | `cloud=AzureGermanCloud` |

## 🎪 Helper Functions (The Convenience Store)

After sourcing `az-profile-helpers.sh`, you get these super convenient functions:

### Quick Commands
```bash
azp                    # List all profiles
azp mycompany         # Activate mycompany profile
azp status            # Show current status
azp deactivate        # Deactivate current profile
```

### Full Commands  
```bash
azp-list              # List profiles
azp-create myprofile  # Create profile
azp-login myprofile   # Login to profile
azp-run myprofile devops project list  # Run command with profile
azp-help              # Show helper help
```

## 📂 Directory Structure

```
~/.az-profiles/                    # Default profile storage
├── .active-profile               # Tracks currently active profile
├── company-prod/                 # Individual profile directories
│   ├── config                   # Azure CLI config
│   └── ...                      # Other Azure CLI files
├── company-dev/
└── personal/

# Or use custom location with:
export AZ_PROFILE_DIR="/path/to/my/profiles"
```

## 🔧 Advanced Configuration

### Environment Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `AZ_PROFILE_DIR` | Custom profiles directory | `~/.az-profiles` |

### Integration with Shell

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
# Load Azure CLI Profile Manager helpers
source /path/to/az-profile-helpers.sh

# Optional: Set custom profile directory
export AZ_PROFILE_DIR="$HOME/my-azure-profiles"

# Optional: Show current profile in prompt
export PS1="[azp:\$(cat ~/.az-profiles/.active-profile 2>/dev/null || echo 'none')] $PS1"
```

## 🎯 Real-World Examples

### Scenario 1: The Multi-Company Consultant
```bash
# Set up profiles for different clients
./az-profile create client-a --profile-url https://github.com/client-a/azure-configs.git --profile-name production
./az-profile create client-b --profile-url https://github.com/client-b/azure-configs.git --profile-name staging

# Switch between clients seamlessly
azp client-a
azp-run client-a devops project list

azp client-b  
azp-run client-b repos list
```

### Scenario 2: The DevOps Engineer
```bash
# Create profiles for different environments
./az-profile create prod --type cloud --org https://dev.azure.com/company --cloud AzureCloud
./az-profile create staging --type cloud --org https://dev.azure.com/company --cloud AzureCloud
./az-profile create dev --type server --org https://devops-internal.company.com --pat-file ./dev.pat

# Daily workflow
azp dev           # Start with development
# ... do dev work ...
azp staging       # Test in staging
# ... verify changes ...
azp prod          # Deploy to production
# ... profit! 💰
```

### Scenario 3: The Automation Hero
```bash
# Batch import all company profiles
./az-profile create --profile-url https://github.com/company/azure-profiles.git --batch

# Set up CI/CD scripts
#!/bin/bash
for env in dev staging prod; do
    echo "Deploying to $env..."
    ./az-profile run $env devops build queue --definition-id 123
done
```

## 🚨 Troubleshooting

### Common Issues and Solutions

#### "Profile not found" Error
```bash
# Check if profiles directory exists
ls -la ~/.az-profiles/

# List available profiles
./az-profile list

# Create the profile you're trying to use
./az-profile create missing-profile
```

#### Authentication Issues
```bash
# Check current authentication status
./az-profile status

# Re-authenticate
./az-profile login your-profile

# Verify Azure CLI is working
az account show
```

#### Environment Variables Not Set
```bash
# Check if profile is active
echo $AZURE_CONFIG_DIR

# Manually activate if needed
./az-profile activate your-profile
```

### Getting Help

```bash
# General help
./az-profile help

# Helper functions help
azp-help

# Azure CLI help
az --help
```

## 🤝 Contributing

We love contributions! Here's how you can help make this tool even more awesome:

### 🐛 Found a Bug?
1. Check if it's already reported in [Issues](https://github.com/ysginc/az-profile-cli/issues)
2. If not, create a new issue with:
   - Clear description of the problem
   - Steps to reproduce
   - Your environment details
   - Expected vs. actual behavior

### 💡 Have an Idea?
1. Open a [Feature Request](https://github.com/ysginc/az-profile-cli/issues/new?template=feature_request.md)
2. Describe your use case
3. Explain why it would be helpful
4. We'll discuss and collaborate!

### 🔧 Want to Code?
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/awesome-new-feature`)
3. Make your changes
4. Add tests if applicable
5. Update documentation
6. Submit a Pull Request

### 📖 Documentation
- Fix typos
- Improve examples
- Add use cases
- Translate to other languages

## 📋 Roadmap

### 🎯 Coming Soon
- [ ] **GUI Interface** - For those who prefer clicking to typing
- [ ] **Profile Templates** - Pre-configured setups for common scenarios  
- [ ] **Auto-Detection** - Automatically suggest profiles based on current directory
- [ ] **Profile Sync** - Keep profiles synchronized across multiple machines
- [ ] **Integration Tests** - Comprehensive test suite
- [ ] **Windows Support** - PowerShell version for Windows users

### 🌟 Dream Features
- [ ] **VS Code Extension** - Manage profiles directly from your editor
- [ ] **Slack/Teams Integration** - Share and activate profiles via chat
- [ ] **Profile Analytics** - Usage statistics and optimization suggestions
- [ ] **Cloud Profile Storage** - Store profiles in Azure Key Vault
- [ ] **AI Assistant** - Smart profile recommendations

## 📊 Stats & Fun Facts

- 🎯 **Lines of Code**: ~1000+ lines of pure Bash goodness
- ⚡ **Performance**: Switch profiles in <1 second
- 🛡️ **Security**: Supports multiple authentication methods
- 🌍 **Compatibility**: Works on Linux, macOS, and WSL
- 📦 **Dependencies**: Just Bash and Azure CLI
- 🎉 **Fun Factor**: Infinitely high! 

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**TL;DR**: You can use this for anything, anywhere, anytime. Just don't blame us if it becomes your new favorite tool! 😉

## 🙏 Acknowledgments

- **Azure CLI Team** - For building the foundation we build upon
- **Git** - For making profile sharing possible
- **Bash** - For being the reliable workhorse of shell scripting
- **Coffee** ☕ - For fueling late-night coding sessions
- **You** - For using and improving this tool!

## 🎉 Final Words

Managing multiple Azure environments doesn't have to be a pain. With Azure CLI Profile Manager, you can:

- **Switch contexts instantly** ⚡
- **Never work in the wrong environment** 🎯
- **Share configurations with your team** 🤝
- **Automate your workflows** 🤖
- **Actually enjoy DevOps work** 😄

So go ahead, give it a try! Your future self will thank you when you're effortlessly juggling multiple Azure environments like a pro. 

**Happy profiling!** 🚀

---

<div align="center">

**Made with ❤️ and lots of ☕**

[⭐ Star this repo](https://github.com/ysginc/az-profile-cli) | [🐛 Report Bug](https://github.com/ysginc/az-profile-cli/issues) | [💡 Request Feature](https://github.com/ysginc/az-profile-cli/issues)

</div>
