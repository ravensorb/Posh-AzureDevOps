<#

.SYNOPSIS
This command provides retrieve Scope Descriptors from Azure DevOps

.DESCRIPTION
The command will retrieve Azure DevOps scope descriptors (if they exists) 

.PARAMETER AzDoConnect
A valid AzDoConnection object

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.PARAMETER Id
The id of the object to get the desciptor for (user current project as default)

.EXAMPLE
Get-AzDoDescriptors

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Get-AzDoDescriptors()
{
    [CmdletBinding(
    )]
    param
    (
        # Common Parameters
        [parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelinebyPropertyName=$true)][PoshAzDo.AzDoConnectObject]$AzDoConnection,
        [parameter(Mandatory=$false)][string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [parameter(Mandatory=$false)][Guid]$Id = [Guid]::Empty
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

        if ($Id -eq [Guid]::Empty) {
            $Id = $AzDoConnection.ProjectId
        }

        # GET https://vssps.dev.azure.com/3pager/_apis/graph/descriptors?{storagekey}api-version=5.0-preview.1
        $apiUrl = Get-AzDoApiUrl -RootPath "https://vssps.dev.azure.com/$($AzDoConnection.OrganizationName)" -ApiVersion $ApiVersion -BaseApiPath "/_apis/graph/descriptors/$($Id)" -QueryStringParams $apiParams

        $descriptors = Invoke-RestMethod $apiUrl -Headers $AzDoConnection.HttpHeaders
        
        Write-Verbose "---------DESCRIPTORS---------"
        Write-Verbose ($descriptors| ConvertTo-Json -Depth 50 | Out-String)
        Write-Verbose "---------DESCRIPTORS---------"

        if ($null -ne $descriptors) {
            return $descriptors.value;
        }
        
        Write-Verbose "No descriptors found."
        
        return $null
    }
    END 
    { 
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}

