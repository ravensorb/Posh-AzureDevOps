function Import-AzDoLibraryVariables()
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
        [switch]$Force,
        [string]$ApiVersion = $global:AzDoApiVersion
    )
    BEGIN
    {
        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0-preview.1"}
                
        Write-Host "Importing Variables into Azure DevOps Variable Groups" -ForegroundColor Green
        Write-Host "`tProject: $ProjectUrl" -ForegroundColor Yellow
        Write-Host "`tCSV File: $csvFile" -ForegroundColor Yellow
        Write-Host "`tVariable Group: $VariableGroupName" -ForegroundColor Yellow
        Write-Host "`tEnvrionment Name: $EnvironmentNameFilter" -ForegroundColor Yellow
        Write-Host "`tCreate Variable Group If doesn't Exists: $Force" -ForegroundColor Yellow
        Write-Host "`tClear Variable Group before importing: $Reset" -ForegroundColor Yellow

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
        $variables | % { Add-AzDoLibraryVariable -ProjectUrl $ProjectUrl -PAT $PAT -ApiVersion $ApiVersion -VariableGroupName $VariableGroupName -VariableName $($_.Name) -VariableValue $($_.Value) -Secret $($_.Secret) -Force:$Force -Reset:$Reset -Verbose:$Verbose; $Reset = $null; $Force = $null }       

        Write-Host "`tImported $($variables.Count) variables" -ForegroundColor Green
    }
    END { }
}

