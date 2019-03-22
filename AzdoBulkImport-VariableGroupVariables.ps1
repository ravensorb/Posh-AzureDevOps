function AzdoBulkImport-VariableGroupVariables()
{
    [CmdletBinding()]
    param
    (
        [string][parameter(Mandatory = $true)]$ProjectUrl,
        [string][parameter(Mandatory = $true)]$csvFile,
        [string]$VariableGroupName = "*",
        [string]$EnvironmentNameFilter,
        [string]$PAT = "",
        [switch]$Reset,
        [switch]$Force
    )
    BEGIN
    {
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
        $variables | % { AzdoAdd-VariableGroupVariable -ProjectUrl $ProjectUrl -PAT $PAT -VariableGroupName $VariableGroupName -VariableName $($_.Name) -VariableValue $($_.Value) -Secret $($_.Secret) -Force:$Force -Reset:$Reset; $Reset = $null }       
    }
    END { }
}
