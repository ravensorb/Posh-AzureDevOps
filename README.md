# Posh-AzureDevOps
Powershell Scripts related to Azure DevOps

## Working with Variable Groups

### AzdoBulkImport-VariableGroupVariables
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
