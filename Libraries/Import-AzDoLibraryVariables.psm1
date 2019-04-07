<#

.SYNOPSIS
Import variables from a CSV file into an Azure DevOps Library

.DESCRIPTION
This command will import all the variables in a CSV into a specific Azure DevOps Library

.PARAMETER ProjectUrl
The full url for the Azure DevOps Project.  For example https://<organization>.visualstudio.com/<project> or https://dev.azure.com/<organization>/<project>

.PARAMETER csvFile
The path to the CSV file

.PARAMETER VariableGroupName
The name of the variable group in the library to import the values into 

.PARAMETER EnvironmentNameFilter
This is an option parameter and is used to file the variables that are imported by environment (can also be a * for a wild card)

.PARAMETER Reset
Indicates if the ENTIRE library should be reset. This means that ALL values are REMOVED. Use with caution

.PARAMETER Force
Indicates if the library group should be created if it doesn't exist

.PARAMETER PAT
A valid personal access token with at least read access for build definitions

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Import-AzDoLibraryVariables -ProjectUrl https://dev.azure.com/<organizztion>/<project> -csvFile <csv file to import> -VariableGroupName <variable group to import into> -EnvironmentNameFilter <

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Import-AzDoLibraryVariables()
{
    [CmdletBinding()]
    param
    (
        [string][parameter(Mandatory = $true)]$ProjectUrl,
        [string][parameter(Mandatory = $true)]$csvFile,
        [string][parameter(Mandatory = $true)]$VariableGroupName,
        [string]$EnvironmentNameFilter = "*",
        [switch]$Reset,
        [switch]$Force,
        [string]$PAT = "",
        [string]$ApiVersion = $global:AzDoApiVersion
    )
    BEGIN
    {
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }        

        if (-Not $ApiVersion.Contains("preview")) { $ApiVersion = "5.0-preview.1" }
        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0-preview.1"}
                
        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "Parameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "$_ = '$($PSBoundParameters[$_])'" }
    }
    PROCESS
    {
        if ([string]::IsNullOrEmpty($EnvironmentNameFilter)) { $EnvironmentNameFilter = "*" }

        Write-Verbose "Importing CSV File for env $EnvironmentNameFilter : $csvFile"
        $csv = Import-Csv $csvFile

        $variables = @()
        $csv | ? { $_.Env -eq $EnvironmentNameFilter -or $_.Env -like $EnvironmentNameFilter } | % { 
            $variables += [pscustomobject]@{
                Name = $_.Variable;
                Value = $_.Value;
                Secret = $false;
            }
        }

        #$variables 
        Write-Verbose "Creating Variables in Group $VariableGroupName"

        # Note: We only want to run the reset once no matter what so we clear it after the first loop
        $variables | % { Add-AzDoLibraryVariable -ProjectUrl $ProjectUrl -PAT $PAT -ApiVersion $ApiVersion -VariableGroupName $VariableGroupName -VariableName $($_.Name) -VariableValue $($_.Value) -Secret $($_.Secret) -Force:$Force -Reset:$Reset; $Reset = $null; $Force = $null }       

        Write-Host "`tImported $($variables.Count) variables" -ForegroundColor Green
    }
    END { }
}

