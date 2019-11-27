<#

.SYNOPSIS
Connect to Azure DevOps

.DESCRIPTION
This command will create a connection to Azure DevOps

.PARAMETER ProjectUrl
The full project url to connect to. Ex: https://dev.azure.com/<org>/<project>

.PARAMETER OrganziationUrl
The organziation url to connect to, Ex: https://dev.auzre.com/<org>

.PARAMETER ProjectName
Then name of the project to connect to

.PARAMETER Force
Force a reconnection

.PARAMETER PAT
The Personal Access Toen (PAT) to use for authentication

.EXAMPLE
Connect-AzDo -OrganizationUrl https://dev.azure.com/someorg -ProjectName SomeProject -PAT <PAT Token>

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
        [string][parameter(ParameterSetName = "FullUrl", Mandatory = $true, ValueFromPipelinebyPropertyName=$true)]$ProjectUrl,
        [string][parameter(ParameterSetName = "OrgUrlAndProjectName", Mandatory = $true, ValueFromPipelineByPropertyName)]$OrganizationUrl,
        [string][parameter(ParameterSetName = "OrgUrlAndProjectName", Mandatory = $true, ValueFromPipelineByPropertyName)]$ProjectName,
        [string][parameter(Mandatory = $false, ValueFromPipelinebyPropertyName=$true)]$PAT,
        [string][Parameter(DontShow)]$OAuthToken,
        [switch][parameter(DontShow)]$LocalOnly,
        [switch]$Force
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

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "Parameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "$_ = '$($PSBoundParameters[$_])'" }
    }
    PROCESS
    {
        if ($Force) 
        {
            $Global:AzDoActiveConnection = $null
        }

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
            if ($null -ne $projectDetails) {
                $azdoConnection.ProjectId = $projectDetails.id
            }
        }
        catch {
            Write-Error -ErrorAction $errorPreference -Message "Project $($azdoConnection.ProjectName) does not exist"            
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
