<#

.SYNOPSIS
This commend provides retrieve members for a specifc Team from Azure DevOps

.DESCRIPTION
The command will retrieve members for the Azure DevOps teams specified 

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
Get-AzDoTeamMemebers -ProjectUrl https://dev.azure.com/<organizztion>/<project> -TeamName <name>

.EXAMPLE
Get-AzDoTeamMemebers -ProjectUrl https://dev.azure.com/<organizztion>/<project> -Teamid <id>
.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Get-AzDoTeamMemebers()
{
    [CmdletBinding(
        DefaultParameterSetName='Name'
    )]
    param
    (
        # Common Parameters
        [PoshAzDo.AzDoConnectObject][parameter(ValueFromPipelinebyPropertyName = $true, ValueFromPipeline = $true)]$AzDoConnection,
        [string][parameter(ValueFromPipelinebyPropertyName = $true)]$ProjectUrl,
        [string][parameter(ValueFromPipelinebyPropertyName = $true)]$PAT,
        [string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [string][parameter(ParameterSetName='Name')][Alias("name")]$TeamName,
        [string][parameter(ParameterSetName='ID')][Alias("id")]$TeamId
    )
    BEGIN
    {
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }        

        if (-Not $ApiVersion.Contains("preview")) { $ApiVersion = "5.0-preview.2" }
        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0-preview.2"}


        if (-Not (Test-Path varaible:$AzDoConnection) -or $AzDoConnection -eq $null)
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

        if ([string]::IsNullOrEmpty($TeamName) -and [string]::IsNullOrEmpty($TeamId)) { throw "Specify a Tean Name or Team ID" }

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "`tParameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "`t`t$_ = '$($PSBoundParameters[$_])'" }        
    }
    PROCESS
    {
        $apiParams = @()

        # https://dev.azure.com/{organization}/_apis/projects/{projectId}/teams/{teamId}/members?api-version=5.0
        if (-Not [string]::IsNullOrEmpty($TeamName))
        {
            $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.OrganizationUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/projects/$($AzDoConnection.ProjectName)/teams/$($TeamName)/members" -QueryStringParams $apiParams
        } 
        elseif ([string]::IsNullOrEmpty($TeamId))
        {
            $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.OrganizationUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/projects/$($AzDoConnection.ProjectName)/teams/$($TeamId)/members" -QueryStringParams $apiParams
        }

        $teams = Invoke-RestMethod $apiUrl -Headers $AzDoConnection.HttpHeaders
        
        Write-Verbose "---------TEAM MEMBERS---------"
        Write-Verbose $teams
        Write-Verbose "---------TEAM MEMBERS---------"

        return $teams.value.identity
    }
    END { }
}

