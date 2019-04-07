<#

.SYNOPSIS
Remove a variable from a specific Azure DevOps libary

.DESCRIPTION
The  command will removea variable to the specificed library

.PARAMETER ProjectUrl
The full url for the Azure DevOps Project.  For example https://<organization>.visualstudio.com/<project> or https://dev.azure.com/<organization>/<project>

.PARAMETER VariableGroupName
The name of the variable group to create/update

.PARAMETER VariableName
Tha name of the variable to create/update

.PARAMETER All
Remove all variables in the library (VariableName is ignored when this is set)

.PARAMETER PAT
A valid personal access token with at least read access for build definitions

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Remove-AzDoLibraryVariable -ProjectUrl https://dev.azure.com/<organizztion>/<project> -DefinitionName <build defintiion name> -VariableName <variable name> -PAT <personal access token>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Remove-AzDoLibraryVariable()
{
    [CmdletBinding()]
    param
    (
        [string][parameter(Mandatory = $true)]$ProjectUrl,
        [string][parameter(Mandatory = $true)]$VariableGroupName,
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
    
        if (-Not $ApiVersion.Contains("preview")) { $ApiVersion = "5.0-preview.1" }
        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0-preview.1"}

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "Parameter Values"

        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "$_ = '$($PSBoundParameters[$_])'" }

        $headers = Get-AzDoHttpHeader -PAT $PAT -ApiVersion $ApiVersion
    }
    PROCESS
    {
        $variableGroup = Get-AzDoLibraryVariableGroup $ProjectUrl $VariableGroupName -PAT $PAT -ApiVersion $ApiVersion

        if(-Not $variableGroup)
        {
            throw "Cannot add variable to nonexisting variable group $VariableGroupName; use the -Force switch to create the variable group."

        }

        $apiUrl = Get-AzDoApiUrl -ProjectUrl $ProjectUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/distributedtask/variablegroups/$($variableGroup.id)"

        Write-Verbose "Variable group $VariableGroupName exists."

        [bool]$found = $false
        foreach($prop in $variableGroup.variables.PSObject.Properties.Where{$_.MemberType -eq "NoteProperty" -and (($_.Name -eq $VariableName) -or $All)})
        {
            Write-Verbose "Removing variable: $($prop.Name)"

            $variableGroup.variables.PSObject.Properties.Remove($prop.Name)

            $found = $true
        }

        if (-Not $found)
        {
            Write-Verbose "Variable not found"

            return
        }

        #Write-Verbose "Persist variable group $VariableGroupName."
        $body = $variableGroup | ConvertTo-Json -Depth 10 -Compress

        #Write-Verbose $body
        $response = Invoke-RestMethod $apiUrl -Method Put -Body $body -ContentType 'application/json' -Header $headers
        
    }
    END
    {
        Write-Verbose "Response: $($response.id)"

        #$response
        return $true
    }
}
