<#

.SYNOPSIS
Connect to Azure DevOps

.DESCRIPTION
This command will create a connection to Azure DevOps

.PARAMETER ProjectUrl
The full url for the Azure DevOps Project.  For example https://<organization>.visualstudio.com/<project> or https://dev.azure.com/<organization>/<project>

.PARAMETER PAT
A valid personal access token with at least read access for build definitions

.EXAMPLE
Connect-AzDo -ProjectUrl https://dev.azure.com/<organizztion>/<project> -PAT <PAT Token>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Connect-AzDo()
{
    [CmdletBinding(
        DefaultParameterSetName = "FullUrl"
    )]
    param
    (
        [string][parameter(ParameterSetName = "FullUrl", Mandatory = $true, ValueFromPipelinebyPropertyName = $true)]$ProjectUrl,
        [string][parameter(ParameterSetName = "OrgUrlAndProjectName", Mandatory = $true, ValueFromPipelineByPropertyName)]$OrganizationUrl,
        [string][parameter(ParameterSetName = "OrgUrlAndProjectName", Mandatory = $true, ValueFromPipelineByPropertyName)]$ProjectName,
        [string][parameter(Mandatory = $false, ValueFromPipelinebyPropertyName = $true)]$PAT,
        [string][Parameter(DontShow)]$OAuthToken,
        [switch][parameter(DontShow)]$LocalOnly
    )
    BEGIN
    {
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }        

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "Parameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "$_ = '$($PSBoundParameters[$_])'" }
    }
    PROCESS
    {
        if (-Not [string]::IsNullOrEmpty($ProjectUrl))
        {
            $azdoConection = [PoshAzDo.AzDoConnectObject]::CreateFromUrl($ProjectUrl)
        } 
        elseif (-Not [string]::IsNullOrEmpty($OrganizationUrl))
        {
            $azdoConection = [PoshAzDo.AzDoConnectObject]::CreateFromUrl($OrganizationUrl)
            $azdoConection.ProjectName = $ProjectName
        }

        Write-Verbose "Connection:"
        Write-Verbose "Organization Name $($azdoConection.OrganizationName)"
        Write-Verbose "Project Name: $($azdoConection.ProjectName)"
        Write-Verbose "Project Url: $($azdoConection.ProjectUrl)"
        Write-Verbose "Release Management Url: $($azdoConection.ReleaseManagementUrl)"

        $headers = Get-AzDoHttpHeader -ProjectUrl $azdoConection.ProjectUrl -PAT $PAT

        $azdoConection.PAT = $PAT
        $azdoConection.HttpHeaders = $headers

        if (-Not $LocalOnly)
        {
            Write-Verbose "`tStoring connection in global scope"
            $Global:AzDoActiveConnection = $azdoConection
        }

        $azdoConection
    }
    END
    { 
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}
