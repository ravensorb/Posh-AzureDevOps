<#

.SYNOPSIS
Removes the speciifed library group if it exists

.DESCRIPTION
The command will remove the specificed library group

.PARAMETER ProjectUrl
The full url for the Azure DevOps Project.  For example https://<organization>.visualstudio.com/<project> or https://dev.azure.com/<organization>/<project>

.PARAMETER VaraibleGroupName
The name of the variable group to remove

.PARAMETER PAT
A valid personal access token with at least read access for build definitions

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Remove-AzDoLibraryVariableGroup -ProjectUrl https://dev.azure.com/<organizztion>/<project> -VariableGroupName <variable group name> -PAT <personal access token>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Remove-AzDoLibraryVariableGroup()
{
    [CmdletBinding()]
    param
    (
        [string][parameter(Mandatory = $true, ValueFromPipelinebyPropertyName = $true)]$ProjectUrl,
        [string][parameter(Mandatory = $true, ValueFromPipelinebyPropertyName = $true)][Alias("name")]$VariableGroupName,
        [string][parameter(Mandatory = $true, ValueFromPipelinebyPropertyName = $true)]$PAT,
        [string]$ApiVersion
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
        $method = "DELETE"

        $variableGroup = Get-AzDoLibraryVariableGroup -ProjectUrl $ProjectUrl -VariableGroupName $VariableGroupName -PAT $PAT -ApiVersion $ApiVersion

        if (-Not $variableGroup) 
        {
            Write-Verbose "Variable group $VariableGroupName does not exist"

            return
        }

        Write-Verbose "Variable group $VariableGroupName not found."

        Write-Verbose "Create variable group $VariableGroupName."

        # DELETE https://dev.azure.com/{organization}/{project}/_apis/distributedtask/variablegroups/{groupId}?api-version=5.0-preview.1
        $apiUrl = Get-AzDoApiUrl -ProjectUrl $ProjectUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/distributedtask/variablegroups/$($variableGroup.id)"

        #Write-Verbose $body
        $response = Invoke-RestMethod $apiUrl -Method $method -ContentType 'application/json' -Header $headers    

        Write-Verbose "Response: $($response.id)"

        #$response
        return $true
    }
    END
    {
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}
