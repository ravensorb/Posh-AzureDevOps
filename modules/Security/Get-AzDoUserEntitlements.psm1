<#

.SYNOPSIS
This command provides retrieve Users from Azure DevOps

.DESCRIPTION
The command will retrieve Azure DevOps users (if they exists) 

.PARAMETER AzDoConnect
A valid AzDoConnection object

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Get-AzDoUserEntitlements

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Get-AzDoUserEntitlements()
{
    [CmdletBinding(
        DefaultParameterSetName="Id"
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

        if (-Not $ApiVersion.Contains("preview")) { $ApiVersion = "5.1-preview.2" }
        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.1-preview.2"}

        if (-Not (Test-Path varaible:$AzDoConnection) -and $AzDoConnection -eq $null)
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

        # GET https://vsaex.dev.azure.com/{organization}/_apis/userentitlements?api-version=5.1-preview.2
        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.VsaexUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/userentitlements" -QueryStringParams $apiParams
        #$tmpUrl = "https://vsaex.dev.azure.com/$($AzDoConnection.OrganizationName)/"
        #$apiUrl = Get-AzDoApiUrl -RootPath $tmpUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/userentitlements" -QueryStringParams $apiParams

        $users = Invoke-RestMethod $apiUrl -Headers $AzDoConnection.HttpHeaders
        
        Write-Verbose "---------USERS---------"
        Write-Verbose ($users| ConvertTo-Json -Depth 50 | Out-String)
        Write-Verbose "---------USERS---------"

        if ($null -ne $users)
        {
            return $users.members
        }
    }
    END 
    { 
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}

