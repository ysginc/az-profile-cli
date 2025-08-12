# Azure DevOps Profile Configuration
# Profile: Example Server (Company Azure DevOps Server)

[profile]
name=example-server
type=server
description=Example Company Azure DevOps Server

[azure]
# Azure cloud environment (optional)
# cloud=AzureCloud

[devops]
organization=https://devops.example-company.com/DefaultCollection

[auth]
# Authentication method: pat, azure-ad, interactive
method=pat
# PAT token (can be inline or reference to file/env var)
pat_file=./example-server-pat
# Alternative: pat_env=EXAMPLE_SERVER_PAT
# Alternative: pat=<direct_token>

[defaults]
# Additional default settings
# project=MyProject
