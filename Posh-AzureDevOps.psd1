#
# Module manifest for module 'Posh-AzureDevOps'
#
# Generated by: Shawn Anderson
#
# Generated on: 10/8/2019
#

@{

# Script module or binary module file associated with this manifest.
# RootModule = ''

# Version number of this module.
ModuleVersion = '1.0.5'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '485c160b-9ec0-489d-8d56-8cdc2947b85c'

# Author of this module
Author = 'Shawn Anderson'

# Company or vendor of this module
CompanyName = 'Invisionware'

# Copyright statement for this module
Copyright = '2019'

# Description of the functionality provided by this module
Description = 'Powershell Module for Azure DevOps'

# Minimum version of the Windows PowerShell engine required by this module
# PowerShellVersion = ''

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = 'bin\PoshAzDoClasses.dll'

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
NestedModules = @(
    '.\modules\Builds\Add-AzDoBuildPipelineVariable.psm1',                                                                  
    '.\modules\Builds\Get-AzDoBuildDefinition.psm1',
    '.\modules\Builds\Get-AzDoBuildPipelineVariables.psm1',
    '.\modules\Builds\Get-AzDoBuilds.psm1',
    '.\modules\Builds\Get-AzDoBuildWorkItems.psm1',
    '.\modules\Builds\Remove-AzDoBuildPipelineVariable.psm1',
    '.\modules\Libraries\Add-AzDoVariableGroupResourceAssignment.psm1',
    '.\modules\Libraries\Add-AzDoVariableGroupVariable.psm1',
    '.\modules\Libraries\Get-AzDoVariableGroupResourceAssignments.psm1',
    '.\modules\Libraries\Get-AzDoVariableGroupRoleDefinitions.psm1',
    '.\modules\Libraries\Get-AzDoVariableGroups.psm1',
    '.\modules\Libraries\Import-AzDoVariableGroupVariables.psm1',
    '.\modules\Libraries\New-AzDoVariableGroup.psm1',
    '.\modules\Libraries\Remove-AzDoVariableGroup.psm1',
    '.\modules\Libraries\Remove-AzDoVariableGroupResourceAssignment.psm1',
    '.\modules\Libraries\Remove-AzDoVariableGroupVariable.psm1',
    '.\modules\Libraries\Set-AzDoVariableGroupPermissionInheritance.psm1',
    '.\modules\Projects\Get-AzDoProjectDetails.psm1',
    '.\modules\Projects\Get-AzDoProjects.psm1',
    '.\modules\Releases\Add-AzDoReleasePipelineVaraibleGroup.psm1',
    '.\modules\Releases\Add-AzDoReleasePipelineVariable.psm1',
    '.\modules\Releases\Get-AzDoRelease.psm1',
    '.\modules\Releases\Get-AzDoReleaseDefinition.psm1',
    '.\modules\Releases\Get-AzDoReleasePipelineVariableGroups.psm1',
    '.\modules\Releases\Get-AzDoReleasePipelineVariables.psm1',
    '.\modules\Releases\Get-AzDoReleaseWorkItems.psm1',
    '.\modules\Releases\Remove-AzDoReleasePipelineVariable.psm1',
    '.\modules\Repos\Get-AzDoRepoBranches.psm1',
    '.\modules\Security\Add-AzDoSecurityGroupMember.psm1',
    '.\modules\Security\Get-AzDoIdentities.psm1',
    '.\modules\Security\Get-AzDoSecurityGroupMemebers.psm1',
    '.\modules\Security\Get-AzDoSecurityGroups.psm1',
    '.\modules\Security\Get-AzDoSubjectLookup.psm1',
    '.\modules\Security\Get-AzDoTeamMembers.psm1',
    '.\modules\Security\Get-AzDoTeams.psm1',
    '.\modules\Security\Get-AzDoUserDetails.psm1',
    '.\modules\Security\Get-AzDoUserEntitlements.psm1',
    '.\modules\Security\Get-AzDoUsers.psm1',
    '.\modules\Security\New-AzDoSecurityGroup.psm1',
    '.\modules\Security\New-AzDoTeam.psm1',
    '.\modules\Security\Remove-AzDoSecurityGroup.psm1',
    '.\modules\Security\Remove-AzDoSecurityGroupMember.psm1',
    '.\modules\Security\Remove-AzDoTeam.psm1',
    '.\modules\ServiceEndpoints\Add-AzDoServiceEndpointSecurityRole.psm1',
    '.\modules\ServiceEndpoints\Get-AzDoServiceEndpointRoles.psm1',
    '.\modules\ServiceEndpoints\Get-AzDoServiceEndpoints.psm1',
    '.\modules\Utilities\Connect-AzDo.psm1',
    '.\modules\Utilities\Get-AzDoActiveConnection.psm1',
    '.\modules\Utilities\Get-AzDoApiUrl.psm1',
    '.\modules\Utilities\Get-AzDoDescriptors.psm1',
    '.\modules\Utilities\Get-AzDoHttpHeader.psm1',
    '.\modules\Utilities\Set-AzDoGlobalVariables.psm1'    
)

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = '*'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
# VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        # Tags = @()

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/ravensorb/Posh-AzureDevOps'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/ravensorb/Posh-AzureDevOps'

        # A URL to an icon representing this module.
        IconUri = 'https://github.com/ravensorb/Posh-AzureDevOps'

        # ReleaseNotes of this module
        ReleaseNotes = 'Cleanup and Fixes'

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

 } # End of PrivateData hashtable

# HelpInfo URI of this module
HelpInfoURI = 'https://github.com/ravensorb/Posh-AzureDevOps'

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

