<#

.SYNOPSIS
This commend provides creates a new Team for Azure DevOps

.DESCRIPTION
The command will create a new Azure DevOps Team

.PARAMETER AzDoConnect
A valid AzDoConnection object

.PARAMETER ProjectUrl
The full url for the Azure DevOps Project.  For example https://<organization>.visualstudio.com/<project> or https://dev.azure.com/<organization>/<project>

.PARAMETER PAT
A valid personal access token with at least read access for build definitions

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.PARAMETER TeamName
The name of the group to create

.EXAMPLE
Create-AzDoTeam -TeamName <team name>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function New-AzDoTeam()
{
    [CmdletBinding(
        DefaultParameterSetName="Name"
    )]
    param
    (
        # Common Parameters
        [PoshAzDo.AzDoConnectObject][parameter(ValueFromPipelinebyPropertyName = $true, ValueFromPipeline = $true)]$AzDoConnection,
        [string][parameter(ValueFromPipelinebyPropertyName = $true)]$ProjectUrl,
        [string][parameter(ValueFromPipelinebyPropertyName = $true)]$PAT,
        [string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [string][parameter(ValueFromPipelinebyPropertyName = $true)]$TeamName,
        [string]$TeamDescription
    )
    BEGIN
    {
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }        

        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0"}

        if (-Not (Test-Path varaible:$AzDoConnection) -and $null -eq $AzDoConnection)
        {
            if ([string]::IsNullOrEmpty($ProjectUrl))
            {
                $AzDoConnection = Get-AzDoActiveConnection

                if ($null -eq $AzDoConnection) { throw "AzDoConnection or ProjectUrl must be valid" }
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

        # POST https://dev.azure.com/{organization}/_apis/projects/{projectId}/teams?api-version=5.0
        # {
        #    "name": "Team Name",
        # }
        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.OrganizationUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/projects/$($AzDoConnection.ProjectName)/teams" -QueryStringParams $apiParams
        $teamDetails = @{name=$TeamName; description=$TeamDescription}
        $body = $teamDetails | ConvertTo-Json -Depth 10 -Compress

        Write-Verbose $body

        $team = Invoke-RestMethod $apiUrl -Method POST -Body $body -ContentType 'application/json' -Header $($AzDoConnection.HttpHeaders)    
        
        Write-Verbose "---------TEAM---------"
        Write-Verbose $team
        Write-Verbose "---------TEAM---------"

        $team
    }
    END { }
}

