<#

.SYNOPSIS
This commend provides retrieve Teams from Azure DevOps

.DESCRIPTION
The command will retrieve Azure DevOps teams (if they exists) 

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
Get-AzDoTeams -ProjectUrl https://dev.azure.com/<organizztion>/<project>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Get-AzDoTeams()
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
        [string][parameter()]$TeamName,
        [switch][parameter()]$Mine
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

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "`tParameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "`t`t$_ = '$($PSBoundParameters[$_])'" }        
    }
    PROCESS
    {
        $apiParams = @()

        if ($Mine) 
        {
            $apiParams += "Mine=true"
        }

        # https://dev.azure.com/{organization}/_apis/projects/{projectId}/teams?api-version=5.0
        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.OrganizationUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/projects/$($AzDoConnection.ProjectName)/teams" -QueryStringParams $apiParams

        $teams = Invoke-RestMethod $apiUrl -Headers $AzDoConnection.HttpHeaders
        
        Write-Verbose "---------TEAMS---------"
        Write-Verbose $teams
        Write-Verbose "---------TEAMS---------"

        if ($teams.count -ne $null)
        {   
            if (-Not [string]::IsNullOrEmpty($TeamName))
            {
                foreach($bd in $teams.value)
                {
                    if ($bd.name -like $TeamName){
                        Write-Verbose "Team Found $($bd.name) found."

                        # https://dev.azure.com/{organization}/_apis/projects/{projectId}/teams/{teamId}?api-version=5.0
                        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.OrganizationUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/projects/$($AzDoConnection.ProjectName)/teams/$($bd.id)" 
                        $teamDetails = Invoke-RestMethod $apiUrl -Headers $AzDoConnection.HttpHeaders

                        return $teamDetails
                    }                     
                }
            }
            else {
                return $teams.value
            }

            Write-Verbose "Team $TeamName not found."

            return $null
        } 
        elseif ($teams -ne $null) {
            return $teams
        }

        Write-Verbose "Team $TeamName not found."
        
        return $null
    }
    END { }
}

