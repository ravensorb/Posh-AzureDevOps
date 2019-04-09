<#

.SYNOPSIS
Get all variables in a specific Azure DevOps libary

.DESCRIPTION
The  command will retreive all variables to the specificed library

.PARAMETER ProjectUrl
The full url for the Azure DevOps Project.  For example https://<organization>.visualstudio.com/<project> or https://dev.azure.com/<organization>/<project>

.PARAMETER VariableGroupName
The name of the variable group to retrieve

.PARAMETER PAT
A valid personal access token with at least read access for build definitions

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Get-AzDoLibraryVariableGroup -ProjectUrl https://dev.azure.com/<organizztion>/<project> -VariableGroupName <variable group name> -PAT <personal access token>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Get-AzDoLibraryVariableGroup()
{
    [CmdletBinding()]
    param
    (
        [string][parameter(Mandatory = $true, ValueFromPipelinebyPropertyName = $true)]$ProjectUrl,
        [string][parameter(ValueFromPipelinebyPropertyName = $true)]$VariableGroupName = "*",
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
        $apiUrl = Get-AzDoApiUrl -ProjectUrl $ProjectUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/distributedtask/variablegroups"

        $variableGroups = Invoke-RestMethod $apiUrl -Headers $headers
        
        Write-Verbose $variableGroups

        foreach($variableGroup in $variableGroups.value){
            if ($variableGroup.name -like $VariableGroupName){
                Write-Verbose "Variable group $($variableGroup.name) found."
                
                $variableGroup
            }   
        }
    }
    END 
    { 
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}
