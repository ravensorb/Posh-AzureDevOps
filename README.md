# Posh-AzureDevOps
Powershell Module for working with Azure DevOps

## Getting Started
Download the files into a specific folder and then run the script ".\Import-AzDoModules.ps1".  This will import all of the modules correctly so they can be executed like any standard powershell command.  After this, use the Connect-AzDo module to create a connection to your Azure DevOps instance.  This will create a connection and setup the environment so all other calls can be made without needed to pass connection details in explicity.

```
./Conntet-AzDo -OrganizationUrl <Org URL> -ProjectName <project name> -PAT <PAT token with full access>

./
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
* Add-AzDoLibraryVariable
* Get-AzDoLibraryVariableGroup
* Import-AzDoLibraryVariables
* New-AzDoLibraryVariableGroup
* Remove-AzDoLibraryVariable
* Remove-AzDoLibraryVariableGroup

### Projects
Get-AzDoProjectDetails
Get-AzDoProjects

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
Get-AzDoSecurityGroupMemebers
Get-AzDoSecurityGroups
Get-AzDoTeamMembers
Get-AzDoTeams
Get-AzDoUserDetails
Get-AzDoUsers

## Example
### Working With Libraries
For some quick background, check out this blog article: http://itramblings.com/2019/03/managing-vsts-tfs-release-definition-variables-from-powershell/

#### Import-AzDoLibraryVariables
This script will do a bulk import from a CSV file into a specific Azure DevOps Variable group.  

**Parameters**
* ProjectUrlThe full URL to the Azure DevOps Project
* csvFileThe full path to the csv file (see below for format)
* VariableGroupNameThe name of the variable group in the library to work with
* EnvrionmentNameFilterThe specific environment to import (set to * to import everything in the csv file)
* PATA valid personal access token with permissions to create/update a variable group
* ResetTells the script to clear out all existing values in the variable group before importing new value
* ForceTells the script to create the variable group if it does not already exist

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
