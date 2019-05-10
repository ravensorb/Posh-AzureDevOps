<#

.SYNOPSIS
This commend provides retrieve Scope Descriptors from Azure DevOps

.DESCRIPTION
The command will retrieve Azure DevOps scope descriptors (if they exists) 

.PARAMETER AzDoConnect
A valid AzDoConnection object

.PARAMETER ProjectUrl
The full url for the Azure DevOps Project.  For example https://<organization>.visualstudio.com/<project> or https://dev.azure.com/<organization>/<project>

.PARAMETER PAT
A valid personal access token with at least read access for build definitions

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
        [PoshAzDo.AzDoConnectObject][parameter(ValueFromPipelinebyPropertyName = $true, ValueFromPipeline = $true)]$AzDoConnection,
        [string][parameter(ValueFromPipelinebyPropertyName = $true)]$ProjectUrl,
        [string][parameter(ValueFromPipelinebyPropertyName = $true)]$PAT,
        [string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [Guid]$Id = [Guid]::Empty
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
            if ([string]::IsNullOrEmpty($ProjectUrl))
            {
                $AzDoConnection = Get-AzDoActiveConnection

                if ($AzDoConnection -eq $null) { throw "AzDoConnection or ProjectUrl must be valid" }
            }
            else 
            {
                $AzDoConnection = Connect-AzDo -ProjectUrl $ProjectUrl -PAT $PAT -LocalOnly
            }
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
        Write-Verbose $descriptors
        Write-Verbose "---------DESCRIPTORS---------"

        if ($descriptors -ne $null) {
            return $descriptors.value;
        }
        
        Write-Verbose "No descriptors found."
        
        return $null
    }
    END { }
}

