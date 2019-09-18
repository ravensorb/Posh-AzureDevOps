<#

.SYNOPSIS
Removes the speciifed library group if it exists

.DESCRIPTION
The command will remove the specificed library group

.PARAMETER VaraibleGroupName
The name of the variable group to remove

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Remove-AzDoLibraryVariableGroup -VariableGroupName <variable group name>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Remove-AzDoLibraryVariableGroup()
{
    [CmdletBinding()]
    param
    (
        # Common Parameters
        [PoshAzDo.AzDoConnectObject][parameter(ValueFromPipelinebyPropertyName = $true, ValueFromPipeline = $true)]$AzDoConnection,
        [string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [string][parameter(Mandatory = $true, ValueFromPipelinebyPropertyName = $true, ParameterSetName="name")][Alias("name")]$VariableGroupName,
        [int][parameter(Mandatory = $true, ValueFromPipelinebyPropertyName = $true, ParameterSetName="id")][Alias("id")]$VariableGroupId
    )
    BEGIN
    {
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }        
    
        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0-preview.1" }
        if (-Not $ApiVersion.Contains("preview")) { $ApiVersion = "5.0-preview.1" }

        if (-Not (Test-Path varaible:$AzDoConnection) -and $AzDoConnection -eq $null)
        {
            $AzDoConnection = Get-AzDoActiveConnection

            if ($AzDoConnection -eq $null) { throw "AzDoConnection or ProjectUrl must be valid" }
        }

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "Parameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "$_ = '$($PSBoundParameters[$_])'" }   
    }
    PROCESS
    {
        $method = "DELETE"

        $variableGroup = Get-AzDoVariableGroups -AzDoConnection $AzDoConnection | ? { $_.name -eq $VariableGroupName -or $_.id -eq $VariableGroupId }

        if (-Not $variableGroup) 
        {
            Write-Verbose "Variable group $VariableGroupName does not exist"

            return
        }

        Write-Verbose "Variable group $VariableGroupName not found."

        Write-Verbose "Create variable group $VariableGroupName."

        # DELETE https://dev.azure.com/{organization}/{project}/_apis/distributedtask/variablegroups/{groupId}?api-version=5.0-preview.1
        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.ProjectUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/distributedtask/variablegroups/$($variableGroup.id)"

        #Write-Verbose $body
        $response = Invoke-RestMethod $apiUrl -Method $method -ContentType 'application/json' -Header $($AzDoConnection.HttpHeaders)    

        Write-Verbose "Response: $($response.id)"

        #$response
        return $true
    }
    END
    {
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}
