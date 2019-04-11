# Posh-AzureDevOps
Powershell Scripts related to Azure DevOps

## Getting Started
Download the files into a specific folder and then run the script ".\Import-AzDoModules.ps1".  This will import all of the modules correctly so they can be executed like any standard powershell command

## Overview

### Connections
* Connect-AzDo

### Build Definitions
* Add-AzDoBuildPipelineVariable
* Get-AzDoBuildDefinition
* Get-AzDoBuildPipelineVariables
* Get-AzDoBuilds
* Get-AzDoBuildWorkItems
* Remove-AzDoBuildPipelineVariable

### Release Definitions
* Add-AzDoReleasePipelineVaraibleGroup
* Add-AzDoReleasePipelineVariable
* Get-AzDoRelease
* Get-AzDoReleaseDefinition
* Get-AzDoReleasePipelineVariableGroups
* Get-AzDoReleasePipelineVariables
* Get-AzDoReleaseWorkItems
* Remove-AzDoReleasePipelineVariable

### Libraries
* Add-AzDoLibraryVariable
* Get-AzDoLibraryVariableGroup
* Import-AzDoLibraryVariables
* New-AzDoLibraryVariableGroup
* Remove-AzDoLibraryVariable
* Remove-AzDoLibraryVariableGroup

### Repositories
* Get-AzDoRepoBranches

## Libraries
http://itramblings.com/2019/03/managing-vsts-tfs-release-definition-variables-from-powershell/

### Examples
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
