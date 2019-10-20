<#

.SYNOPSIS
This command provides retrieve Service Endpoints Groups from Azure DevOps

.DESCRIPTION
The command will retrieve Azure DevOps service endpoints (if they exists) 

.PARAMETER AzDoConnect
A valid AzDoConnection object

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Get-AzDoServiceEndpointSecurityRoles

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Get-AzDoServiceEndpointSecurityRoles()
{
    [CmdletBinding(
        DefaultParameterSetName="Name"
    )]
    param
    (
        # Common Parameters
        [parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelinebyPropertyName=$true)][PoshAzDo.AzDoConnectObject]$AzDoConnection,
        [parameter(Mandatory=$false)][string]$ApiVersion = $global:AzDoApiVersion

        # Module Parameters
    )
    BEGIN
    {
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }  

        $errorPreference = 'Stop'
        if ( $PSBoundParameters.ContainsKey('ErrorAction')) {
            $errorPreference = $PSBoundParameters['ErrorAction']
        }

        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0-preview.1" }
        if (-Not $ApiVersion.Contains("preview")) { $ApiVersion = "5.0-preview.1" }

        if (-Not (Test-Path varaible:$AzDoConnection) -and $null -eq $AzDoConnection)
        {
            $AzDoConnection = Get-AzDoActiveConnection

            if ($null -eq $AzDoConnection) { Write-Error -ErrorAction $errorPreference -Message "AzDoConnection or ProjectUrl must be valid" }
        }

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "`tParameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "`t`t$_ = '$($PSBoundParameters[$_])'" }        
    }
    PROCESS
    {
        $apiParams = @()

        # GET https://dev.azure.com/{organization}/_apis/securityroles/scopes/distributedtask.serviceendpointrole/roledefinitions
        $apiUrl = Get-AzDoApiUrl -RootPath $AzDoConnection.OrganizationUrl -ApiVersion $ApiVersion -BaseApiPath "//_apis/securityroles/scopes/distributedtask.serviceendpointrole/roledefinitions" -QueryStringParams $apiParams

        $results = Invoke-RestMethod $apiUrl -Headers $AzDoConnection.HttpHeaders
        
        Write-Verbose "---------RESULTS---------"
        Write-Verbose ($results| ConvertTo-Json -Depth 50 | Out-String)
        Write-Verbose "---------RESULTS---------"

        if ($results.count -gt 0) 
        {
            $results.value
        }
    }
    END 
    { 
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}

