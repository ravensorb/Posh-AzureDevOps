# Posh-AzureDevOps
Powershell Module for working with Azure DevOps

## Getting Started
Install the Power Shell Model from the gallery
```
Install-Module -Name Posh-AzureDevOps
```
or
Clone/Download the files from the repository into a specific folder and then run the script ".\Import-AzDoModules.ps1".  

This will import all of the modules correctly so they can be executed like any standard powershell command.  

Next use the ```Connect-AzDo``` command to create a connection to your Azure DevOps instance.  This will create a connection and setup the environment so all other calls can be made without needed to pass connection details in explicity.

```
$conn = Conntet-AzDo -OrganizationUrl <Org URL> -ProjectName <project name> -PAT <PAT token with full access>

Get-AzDoUsers
```

## Overview
This module provides a way to work with most of Azure DevOps from PowerShell.  It is broken out by functional areas (Builds, Libraries, Projects, Releases, Repos, Security, and Work Items).

### Connections
* Connect-AzDo

### Build Definitions
* Add-AzDoBuildPipelineVariable
* Get-AzDoBuildDefinition
* Get-AzDoBuildPipelineVariables
* Get-AzDoBuilds
* Get-AzDoBuildWorkItems
* Remove-AzDoBuildPipelineVariable

### Libraries
* Add-AzDoVariableGroupVariable
* Add-AzDoVariableGroupResourceAssignment
* Get-AzDoVariableGroupResourceAssignment
* Get-AzDoVariableGroupRoleDefinitions
* Get-AzDoVariableGroups
* Import-AzDoVariableGroupVariables
* New-AzDoVariableGroupVariables
* Remove-AzDoVariableGroupVariable
* Remove-AzDoVariableGroup
* Remove-AzDoVariableGroupResourceAssignment
* Set-AzDoVariableGroupPermissionInheritance

### Projects
* Get-AzDoProjectDetails
* Get-AzDoProjects

### Release Definitions
* Add-AzDoReleasePipelineVaraibleGroup
* Add-AzDoReleasePipelineVariable
* Get-AzDoRelease
* Get-AzDoReleaseDefinition
* Get-AzDoReleasePipelineVariableGroups
* Get-AzDoReleasePipelineVariables
* Get-AzDoReleaseWorkItems
* Remove-AzDoReleasePipelineVariable

### Repositories
* Get-AzDoRepoBranches

### Security
* Add-AzDoSecurityGroupMemeber
* Get-AzDoSecurityGroupMemebers
* Get-AzDoSecurityGroups
* Get-AzDoTeamMembers
* Get-AzDoTeams
* Get-AzDoUserDetails
* Get-AzDoUsers
* New-AzDoSecurityGroup
* New-AzDoTeam
* Remove-AzDoSecurityGroup
* Remove-AzDoSecurityGroupMemeber
* Remove-AzDoTeam

### Utility
* Connect-AzDo
* Get-AzDoActiveConnection

## Examples
### Working With Libraries
For some quick background, check out this blog article: http://itramblings.com/2019/03/managing-vsts-tfs-release-definition-variables-from-powershell/

#### Import-AzDoVariableGroupVariables
This script will do a bulk import from a CSV file into a specific Azure DevOps Variable group.  

**Parameters**
* AzDoConnect - The current connection to AZDO
* csvFile - The full path to the csv file (see below for format)
* VariableGroupName - The name of the variable group in the library to work with
* EnvrionmentNameFilter - The specific environment to import (set to * to import everything in the csv file)
* Reset - Tells the script to clear out all existing values in the variable group before importing new value
* Force - Tells the script to create the variable group if it does not already exist

**CSV File Format**

The format of the CSV file must be as follows
```"Variable","Value","Env"```
Example:
```
SomeVariable, SomeValue, DEV01
SomeVariable, SomeValue, DEV02
SomeVariable, SomeValue, UAT
SomeVariable, SomeValue, PROD
```
