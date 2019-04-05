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
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }        

        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0"}

        if ([string]::IsNullOrEmpty($ProjectUrl)) { Write-Error "Invalid Project Url"; Exit; }
        if ([string]::IsNullOrEmpty($EnvironmentName)) { $EnvironmentName = "*" }
      
        if ($DefinitionId -eq $null -and [string]::IsNullOrEmpty($DefinitionName)) { Write-Error "Definition ID or Name must be specified"; Exit;}

        # Write-Host "Importing Variable into Azure DevOps Variable Groups" -ForegroundColor Green
        # Write-Host "`tProject: $ProjectUrl" -ForegroundColor Green
        # Write-Host "`tDefinition ID: $DefinitionId" -ForegroundColor Green
        # Write-Host "`tVariable: $VariableName = $VariableValue" -ForegroundColor Green
        # Write-Host "`tEnvironment: $EnvironmentName" -ForegroundColor Green

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "Parameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "$_ = '$($PSBoundParameters[$_])'" }

        $headers = Get-AzDoHttpHeader -PAT $PAT -ApiVersion $ApiVersion 

        $ProjectUrl = Get-AzDoRmUrlFromProjectUrl $ProjectUrl

        $definition = $null

        if ($DefinitionId -ne $null -and $DefinitionId -gt 0)
        {
            $definition = Get-AzDoRmReleaseDefinition -ProjectUrl $ProjectUrl -Id $DefinitionId -PAT $PAT
        }
        elseif ($DefinitionName -ne $null)
        {
            $definition = Get-AzDoRmReleaseDefinition -ProjectUrl $ProjectUrl -Name $DefinitionName -PAT $PAT
        }

        if ($definition -eq $null) { Write-Error "Could not find a valid release definition.  Check your parameters and try again"; Exit;}

    }
    PROCESS
    {
        $apiUrl = Get-AzDoApiUrl -ProjectUrl $ProjectUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/release/definitions/$($definition.Id)" -QueryStringParams "Expand=Environments"
        $definition = Invoke-RestMethod $apiUrl -Headers $headers

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

