<#

.SYNOPSIS
Remove a variable/value to the specified Azure DevOps build pipeline

.DESCRIPTION
The command will remove a variable to the specified Azure DevOps build pipeline

.PARAMETER ProjectUrl
The full url for the Azure DevOps Project.  For example https://<organization>.visualstudio.com/<project> or https://dev.azure.com/<organization>/<project>

.PARAMETER DefinitionId
The id of the build definition to update (use on this OR the name parameter)

.PARAMETER DefinitionName
The name of the build definition to update (use on this OR the id parameter)

.PARAMETER VariableName
Tha name of the variable to create/update

.PARAMETER All
Remove all variables in the library (VariableName is ignored when this is set)

.PARAMETER PAT
A valid personal access token with at least read access for build definitions

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Add-AzDoBuildPipelineVariable -ProjectUrl https://dev.azure.com/<organizztion>/<project> -DefinitionName <build defintiion name> -VariableName <variable name> -PAT <personal access token>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>

function Remove-AzDoBuildPipelineVariable()
{
    [CmdletBinding(
        DefaultParameterSetName='Name'
    )]
    param
    (
        [string][parameter(Mandatory = $true)]$ProjectUrl,
        [int][parameter(ParameterSetName='Id',ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]$DefinitionId = $null,
        [string][parameter(ParameterSetName='Name',ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]$DefinitionName = $null,
        [string][parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][Alias("name")]$VariableName,
        [switch]$All,
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

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "`tParameter Values"
        $PSBoundParameters.Keys | ForEach-Object { if ($Secret -and $_ -eq "VariableValue") { Write-Verbose "`t`tVariableValue = *******" } else { Write-Verbose "`t`t$_ = '$($PSBoundParameters[$_])'" }}

        $headers = Get-AzDoHttpHeader -PAT $PAT -ApiVersion $ApiVersion 
    }
    PROCESS
    {
        $definition = $null

        if ($DefinitionId -ne $null -and $DefinitionId -gt 0)
        {
            $definition = Get-AzDoBuildDefinition -ProjectUrl $ProjectUrl -Id $DefinitionId -PAT $PAT -ExpandFields "variables"
        }
        elseif (-Not [string]::IsNullOrEmpty($DefinitionName))
        {
            $definition = Get-AzDoBuildDefinition -ProjectUrl $ProjectUrl -Name $DefinitionName -PAT $PAT -ExpandFields "variables"
        }

        if ($definition -eq $null) { throw "Could not find a valid build definition.  Check your parameters and try again";}

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

        $apiUrl = Get-AzDoApiUrl -ProjectUrl $ProjectUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/build/definitions/$($definition.id)"

        #$definition.source = "restApi"

        #Write-Verbose "Persist definition $definition."
        $body = $definition | ConvertTo-Json -Depth 10 -Compress

        #Write-Verbose $body
        $response = Invoke-RestMethod $apiUrl -Method Put -Body $body -ContentType 'application/json' -Headers $headers       
    }
    END
    {
        Write-Verbose "Response: $($response.id)"

        #$response
        return $true
    }
}

