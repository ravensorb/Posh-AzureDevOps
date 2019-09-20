<#

.SYNOPSIS
Import variables from a CSV file into an Azure DevOps Library

.DESCRIPTION
This command will import all the variables in a CSV into a specific Azure DevOps Library

.PARAMETER CsvFile
The path to the CSV file.  Format is: Variable, Value, Env, Secret)

.PARAMETER VariableGroupName
The name of the variable group in the library to import the values into 

.PARAMETER EnvironmentNameFilter
This is an option parameter and is used to file the variables that are imported by environment (can also be a * for a wild card)

.PARAMETER Reset
Indicates if the ENTIRE variable should be reset. This means that ALL values are REMOVED. Use with caution

.PARAMETER Force
Indicates if the variable group should be created if it doesn't exist

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Import-AzDoVariableGroupVariables -CsvFile <csv file to import> -VariableGroupName <variable group to import into> -EnvironmentNameFilter <

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Import-AzDoVariableGroupVariables()
{
    [CmdletBinding()]
    param
    (
        # Common Parameters
        [PoshAzDo.AzDoConnectObject][parameter(ValueFromPipelinebyPropertyName = $true, ValueFromPipeline = $true)]$AzDoConnection,
        [string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [string][parameter(Mandatory = $true)]$CsvFile,
        [string][parameter(Mandatory = $true, ValueFromPipelinebyPropertyName = $true)]$VariableGroupName,
        [string]$EnvironmentNameFilter = "*",
        [switch]$Reset,
        [switch]$Force
    )
    BEGIN
    {
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }  

        $errorPreference = 'Stop'
        if ( $PSBoundParameters.ContainsKey('ErrorAction')) {
            $errorPreference = $PSBoundParameters['ErrorAction']
        }

        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0-preview.1" }
        if (-Not $ApiVersion.Contains("preview")) { $ApiVersion = "5.0-preview.1" }

        if (-Not (Test-Path varaible:$AzDoConnection) -and $null -eq $AzDoConnection)
        {
            $AzDoConnection = Get-AzDoActiveConnection

            if ($null -eq $AzDoConnection) { Write-Error -ErrorAction $errorPreference -Message "AzDoConnection or ProjectUrl must be valid" }
        }
                
        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "Parameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "$_ = '$($PSBoundParameters[$_])'" }
    }
    PROCESS
    {
        if ([string]::IsNullOrEmpty($EnvironmentNameFilter)) { $EnvironmentNameFilter = "*" }

        Write-Verbose "Importing CSV File for env $EnvironmentNameFilter : $CsvFile"
        $csv = Import-Csv $CsvFile

        $variables = @()
        $csv | ? { $_.Env -eq $EnvironmentNameFilter -or $_.Env -like $EnvironmentNameFilter } | % { 
            $variables += [pscustomobject]@{
                Name = $_.Variable;
                Value = $_.Value;
                Secret = $_.IsSecret;
            }
        }

        #$variables 
        Write-Verbose "Creating Variables in Group $VariableGroupName"

        # Note: We only want to run the reset once no matter what so we clear it after the first loop
        $variables | % { Add-AzDoVariableGroupVariable -AzDoConnection $AzDoConnection -ApiVersion $ApiVersion -VariableGroupName $VariableGroupName -VariableName $($_.Name) -VariableValue $($_.Value) -Secret $($_.Secret) -Force:$Force -Reset:$Reset; $Reset = $null; $Force = $null }       

        Write-Host "`tImported $($variables.Count) variables" -ForegroundColor Green
    }
    END
    { 
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}

