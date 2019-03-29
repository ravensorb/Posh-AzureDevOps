function Get-AzDoBuildPipelineVariables()
{
    [CmdletBinding()]
    param
    (
        [string][parameter(Mandatory = $true)]$ProjectUrl,
        [int]$DefinitionId = $null,
        [string]$DefinitionName = $null,
        [string][parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][Alias("name")]$VariableName,
        [string]$PAT,
        [string]$ApiVersion = $global:AzDoApiVersion
    )
    BEGIN
    {
       if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0"}

        if ([string]::IsNullOrEmpty($ProjectUrl)) { Write-Error "Invalid Project Url"; Exit; }

        if ($DefinitionId -eq $null -and [string]::IsNullOrEmpty($DefinitionName)) { Write-Error "Definition ID or Name must be specified"; Exit;}

        $definition = $null

        if ($DefinitionId -ne $null)
        {
            $definition = Get-AzDoBuildDefinition -ProjectUrl $ProjectUrl -Id $DefinitionId -PAT $PAT
        }
        elseif ($DefinitionName -ne $null)
        {
            $definition = Get-AzDoBuildDefinition -ProjectUrl $ProjectUrl -Name $DefinitionName -PAT $PAT
        }

        if ($definition -eq $null) { Write-Error "Could not find a valid build definition.  Check your parameters and try again"; Exit;}

        Write-Host "Retrieving Variable form Azure DevOps Build Pipeline" -ForegroundColor Green
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
        $url = "$($ProjectUrl)/_apis/build/definitions/$($definition.Id)?Expand=parameters&api-version=$($ApiVersion)"
        $definition = Invoke-RestMethod $url -Headers $headers

        #Write-Verbose $definition

        $variables = @()

        $definition.variables.PSObject.Properties | ? { $_.MemberType -eq "NoteProperty"} | % { 
            #Write-Verbose "$($_.Name) => $($_.Value)"

            $variables += [pscustomobject]@{
                Name = $_.Name;
                Value = $_.Value.value;
                Secret = $_.Value.isSecret;
                AllowOverride = $_.Value.allowOverride;
            }
        };

        $variables
    }
    END
    {

    }
}

