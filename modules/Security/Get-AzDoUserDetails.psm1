<#

.SYNOPSIS
This command provides retrieve User Details from Azure DevOps

.DESCRIPTION
The command will retrieve Azure DevOps user details (if they exists) 

.PARAMETER AzDoConnect
A valid AzDoConnection object

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.PARAMETER UserDescriptor
The user descriptor

.EXAMPLE
Get-AzDoUserDetails -UserName <username>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Get-AzDoUserDetails()
{
    [CmdletBinding(
    )]
    param
    (
        # Common Parameters
        [parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelinebyPropertyName=$true)][PoshAzDo.AzDoConnectObject]$AzDoConnection,
        [parameter(Mandatory=$false)][string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][Alias("descriptor")][string]$UserDescriptor
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

        if (-Not $ApiVersion.Contains("preview")) { $ApiVersion = "5.0-preview.1" }
        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0-preview.1"}

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

        # https://vssps.dev.azure.com/{organization}/_apis/graph/users/{userDescriptor}?api-version=5.0-preview.1
        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.Vsspurl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/graph/users/$($UserDescriptor)" -QueryStringParams $apiParams

        $user = Invoke-RestMethod $apiUrl -Headers $AzDoConnection.HttpHeaders
        
        Write-Verbose "---------USER DETAILS---------"
        Write-Verbose ($user| ConvertTo-Json -Depth 50 | Out-String)
        Write-Verbose "---------USER DETAILS---------"

        return $user
    }
    END 
    { 
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}

