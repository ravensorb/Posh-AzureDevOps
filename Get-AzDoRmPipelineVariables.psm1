function Get-AzDoRmPipelineVariables()
{
    [CmdletBinding()]
    param
    (
        [string][parameter(Mandatory = $true)]$ProjectUrl,
        [int]$DefinitionId = $null,
        [string]$DefinitionName = $null,
        [string][parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][Alias("name")]$VariableName,
        [string][parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][Alias("env")]$EnvironmentName = $null,
        [string]$PAT,
        [string]$ApiVersion = $global:AzDoApiVersion
    )
    BEGIN
    {
       if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0"}

        $ProjectUrl = Get-AzDoRmUrlFromProjectUrl $ProjectUrl
        if ([string]::IsNullOrEmpty($ProjectUrl)) { Write-Error "Invalid Project Url"; Exit; }
        if ([string]::IsNullOrEmpty($EnvironmentName)) { $EnvironmentName = "*" }

        if ($DefinitionId -eq $null -and [string]::IsNullOrEmpty($DefinitionName)) { Write-Error "Definition ID or Name must be specified"; Exit;}

        $definition = $null

        if ($DefinitionId -ne $null)
        {
            $definition = Get-AzDoRmReleaseDefinition -ProjectUrl $ProjectUrl -Id $DefinitionId -PAT $PAT
        }
        elseif ($DefinitionName -ne $null)
        {
            $definition = Get-AzDoRmReleaseDefinition -ProjectUrl $ProjectUrl -Name $DefinitionName -PAT $PAT
        }

        if ($definition -eq $null) { Write-Error "Could not find a valid release definition.  Check your parameters and try again"; Exit;}

        Write-Host "Importing Variable into Azure DevOps Variable Groups" -ForegroundColor Green
        Write-Host "`tProject: $ProjectUrl" -ForegroundColor Green
        Write-Host "`tDefinition ID: $DefinitionId" -ForegroundColor Green
        Write-Host "`tVariable: $VariableName = $VariableValue" -ForegroundColor Green
        Write-Host "`tEnvironment: $EnvironmentName" -ForegroundColor Green

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "Parameter Values"

        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "$_ = '$($PSBoundParameters[$_])'" }

        $headers = Get-AzDoHttpHeader -PAT $PAT -ApiVersion $ApiVersion 
    }
    PROCESS
    {
        $url = "$($ProjectUrl)/_apis/release/definitions/$($definition.Id)?expand=Environments&api-version=$($ApiVersion)"
        $definition = Invoke-RestMethod $url -Headers $headers

        $variables = @()

        if (-Not [string]::IsNullorEmpty($EnvironmentName)) 
        {
            Write-Verbose "Getting ariables for Environment $EnvironmentName"
            foreach($environment in $definition.environments)
            {
                if ($enviroEnvironmentNamenment -eq "*" -or $environment -like "*$EnvironmentName*") {
                    $environment.variables.PSObject.Properties | ? { $_.MemberType -eq "NoteProperty"} | % { 
                        Write-Verbose $_.Value
                        $variables += [pscustomobject]@{
                            Name = $_.Name;
                            Value = $_.Value.value;
                            Environment = $environment.Name;
                        }
                    }
                }
            }
        }

        $definition.variables.PSObject.Properties | ? { $_.MemberType -eq "NoteProperty"} | % { 
            $variables += [pscustomobject]@{
                Name = $_.Name;
                Value = $_.Value;
                Environment = "Release";
            }
        };

        $variables
    }
    END
    {

    }
}

