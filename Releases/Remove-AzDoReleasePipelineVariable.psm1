<#

.SYNOPSIS
Remove a variable/value to the specified Azure DevOps reelase pipeline

.DESCRIPTION
The command will remove a variable to the specified Azure DevOps reelase pipeline

.PARAMETER ProjectUrl
The full url for the Azure DevOps Project.  For example https://<organization>.visualstudio.com/<project> or https://dev.azure.com/<organization>/<project>

.PARAMETER ReleaseDefinitionId
The id of the reelase definition to update (use on this OR the name parameter)

.PARAMETER ReleaseDefinitionName
The name of the build definition to update (use on this OR the id parameter)

.PARAMETER VariableName
Tha name of the variable to create/update

.PARAMETER All
Remove all variables in the library (VariableName is ignored when this is set)

.PARAMETER PAT
A valid personal access token with at least read access for reelase definitions

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Add-AzDoReleasePipelineVariable -ProjectUrl https://dev.azure.com/<organizztion>/<project> -ReleaseDefinitionName <reelase defintiion name> -VariableName <variable name> -PAT <personal access token>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>

function Remove-AzDoReleasePipelineVariable()
{
    [CmdletBinding(
        DefaultParameterSetName='Name'
    )]
    param
    (
        [string][parameter(Mandatory = $true, ValueFromPipelinebyPropertyName = $true)]$ProjectUrl,
        [int][parameter(ParameterSetName='Id', ValueFromPipelineByPropertyName = $true)]$ReleaseDefinitionId = $null,
        [string][parameter(ParameterSetName='Name', ValueFromPipelineByPropertyName = $true)]$ReleaseDefinitionName = $null,
        [string][parameter( ValueFromPipelineByPropertyName = $true)][Alias("name")]$VariableName,
        [switch]$All,
        [string][parameter(Mandatory = $true, ValueFromPipelinebyPropertyName = $true)]$PAT,
        [string]$ApiVersion = $global:AzDoApiVersion
    )
    BEGIN
    {
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }        

        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0"}

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "`tParameter Values"
        $PSBoundParameters.Keys | ForEach-Object { if ($Secret -and $_ -eq "VariableValue") { Write-Verbose "`t`tVariableValue = *******" } else { Write-Verbose "`t`t$_ = '$($PSBoundParameters[$_])'" }}

        $headers = Get-AzDoHttpHeader -PAT $PAT -ApiVersion $ApiVersion 

        $ProjectUrl = Get-AzDoRmUrlFromProjectUrl $ProjectUrl      
    }
    PROCESS
    {
        $definition = $null

        if ($ReleaseDefinitionId -ne $null -and $ReleaseDefinitionId -gt 0)
        {
            $definition = Get-AzDoReleaseDefinition -ProjectUrl $ProjectUrl -ReleaseDefinitionId $ReleaseDefinitionId -PAT $PAT -ExpandFields "variables"
        }
        elseif (-Not [string]::IsNullOrEmpty($ReleaseDefinitionName))
        {
            $definition = Get-AzDoReleaseDefinition -ProjectUrl $ProjectUrl -ReleaseDefinitionName $ReleaseDefinitionName -PAT $PAT -ExpandFields "variables"
        }

        if ($definition -eq $null) { throw "Could not find a valid release definition.  Check your parameters and try again";}

        [bool]$found = $false
        foreach($prop in $definition.variables.PSObject.Properties.Where{$_.MemberType -eq "NoteProperty" -and (($_.Name -eq $VariableName) -or $All)})
        {
            Write-Verbose "Removing Variable: $($prop.Name)"

            $definition.variables.PSObject.Properties.Remove($prop.Name)

            $found = $true
        }

        if (-Not $found)
        {
            Write-Verbose "Variable not found"

            return
        }
            
        $apiUrl = Get-AzDoApiUrl -ProjectUrl $ProjectUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/release/definitions/$($definition.id)"

        #$definition.source = "restApi"

        #Write-Verbose "Persist definition $definition."
        $body = $definition | ConvertTo-Json -Depth 10 -Compress

        #Write-Verbose $body
        $response = Invoke-RestMethod $apiUrl -Method Put -Body $body -ContentType 'application/json' -Headers $headers | Out-Null        
    }
    END
    {
        Write-Verbose "Response: $($response.id)"

        #$response
        return $true
    }
}

