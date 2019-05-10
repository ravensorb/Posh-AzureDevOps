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
            $azdoConnection = [PoshAzDo.AzDoConnectObject]::CreateFromUrl($ProjectUrl)
        } 
        elseif (-Not [string]::IsNullOrEmpty($OrganizationUrl))
        {
            $azdoConnection = [PoshAzDo.AzDoConnectObject]::CreateFromUrl($OrganizationUrl)
            $azdoConnection.ProjectName = $ProjectName
        }

        $headers = Get-AzDoHttpHeader -ProjectUrl $azdoConnection.ProjectUrl -PAT $PAT

        $azdoConnection.PAT = $PAT
        $azdoConnection.HttpHeaders = $headers

        try {
            $projectDetails = Get-AzDoProjectDetails -AzDoConnection $azdoConnection -ProjectName $azdoConnection.ProjectName
            if ($projectDetails -ne $null) {
                $azdoConnection.ProjectId = $projectDetails.id
            }
        }
        catch {
            throw "Project $($azdoConnection.ProjectName) does not exist"            
        }

        $azdoConnection.ProjectDescriptor = Get-AzDoDescriptors -AzDoConnection $azdoConnection

        if (-Not $LocalOnly)
        {
            Write-Verbose "`tStoring connection in global scope"
            $Global:AzDoActiveConnection = $azdoConnection
        }

        $azdoConnection
    }
    END
    { 
        Write-Verbose "Connection:"
        Write-Verbose "Organization Name: $($azdoConnection.OrganizationName)"
        Write-Verbose "Organization Url: $($azdoConnection.OrganizationUrl)"
        Write-Verbose "Project Name: $($azdoConnection.ProjectName)"
        Write-Verbose "Project Id: $($azdoConnection.ProjectId)"
        Write-Verbose "Project Descriptor: $($azdoConnection.ProjectDescriptor)"
        Write-Verbose "Project Url: $($azdoConnection.ProjectUrl)"
        Write-Verbose "Release Management Url: $($azdoConnection.ReleaseManagementUrl)"

        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}
