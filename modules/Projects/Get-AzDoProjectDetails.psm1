<#

.SYNOPSIS
This commend provides retrieve Project Details from Azure DevOps

.DESCRIPTION
The command will retrieve Azure DevOps project details (if they exists) 

.PARAMETER AzDoConnect
A valid AzDoConnection object

.PARAMETER ProjectUrl
The full url for the Azure DevOps Project.  For example https://<organization>.visualstudio.com/<project> or https://dev.azure.com/<organization>/<project>

.PARAMETER PAT
A valid personal access token with at least read access for build definitions

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.PARAMETER TeamName
The name of the build definition to retrieve (use on this OR the id parameter)

.EXAMPLE
Get-AzDoProjectDetails -ProjectName <project name>

.EXAMPLE
Get-AzDoProjectDetails -ProjectId <project id>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Get-AzDoProjectDetails()
{
    [CmdletBinding(
        DefaultParameterSetName="ID"
    )]
    param
    (
        # Common Parameters
        [PoshAzDo.AzDoConnectObject][parameter(ValueFromPipelinebyPropertyName = $true, ValueFromPipeline = $true)]$AzDoConnection,
        [string][parameter(ValueFromPipelinebyPropertyName = $true)]$ProjectUrl,
        [string][parameter(ValueFromPipelinebyPropertyName = $true)]$PAT,
        [string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [string][parameter(ParameterSetName="Name")][Alias("name")]$ProjectName,
        [Guid][parameter(ParameterSetName="ID", ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][Alias("id")]$ProjectId
    )
    BEGIN
    {
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }        

        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0"}

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

        if ([string]::IsNullOrEmpty($ProjectName) -and $ProjectId -eq $null) { throw "Project Name or ID required" }

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "`tParameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "`t`t$_ = '$($PSBoundParameters[$_])'" }        
    }
    PROCESS
    {
        $apiParams = @()

        # https://dev.azure.com/{organization}/_apis/projects/{projectId}?api-version=5.0
        if (-Not [string]::IsNullOrEmpty($ProjectName))
        {
            $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.OrganizationUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/projects/$($ProjectName)" 
        } else {
            $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.OrganizationUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/projects/$($ProjectId)" 
        }
        $projectDetails = Invoke-RestMethod $apiUrl -Headers $AzDoConnection.HttpHeaders

        Write-Verbose "---------PROJECTS DETAILS---------"
        Write-Verbose $projectDetails
        Write-Verbose "---------PROJECTS DETAILS---------"

        return $projectDetails
    }
    END { }
}
