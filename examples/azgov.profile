# Azure DevOps Profile Configuration
# Profile: Azure Government Cloud

[profile]
name=azure-government
type=cloud
description=Azure Government cloud environment

[azure]
cloud=AzureUSGovernment

[devops]
organization=https://dev.azure.us/myorg

[auth]
method=azure-ad
# For government cloud, typically use Azure AD

[defaults]
# Default project if desired
# project=MyGovernmentProject
