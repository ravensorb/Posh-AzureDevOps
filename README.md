# Posh-AzureDevOps
Powershell Scripts related to Azure DevOps

## Getting Started
Download the files into a specific folder and then run the script ".\Import-AzDoModules.ps1".  This will import all of the modules correctly so they can be executed like any standard powershell command

## Overview

### Build Definitions
* Get-AzDoBuildDefinition          
* Get-AzDoBuildPipelineVariables  

### Release Definitions
* Add-AzDoRmPipelineVariable      
* Get-AzDoRmPipelineVariables.      
* Get-AzDoRmReleaseDefinition      

### Libraries
* Import-AzDoLibraryVariables      
* Add-AzDoLibraryVariable         

### Utility Methods
* Get-AzDoRmUrlFromProjectUrl      
* Set-AzDoGlobalVariables          
* Get-AzDoHttpHeader              

## Libraries
http://itramblings.com/2019/03/managing-vsts-tfs-release-definition-variables-from-powershell/

#### Import-AzDoLibraryVariables
This script will do a bulk import from a CSV file into a specific Azure DevOps Variable group.  

**Parameters**
* ProjectUrl - The full URL to the Azure DevOps Project
* csvFile - The full path to the csv file (see below for format)
* VariableGroupName - The name of the variable group in the library to work with
* EnvrionmentNameFilter - The specific environment to import (set to * to import everything in the csv file)
* PAT - A valid personal access token with permissions to create/update a variable group
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
