<#

.SYNOPSIS
This command provides retrieve members for a specifc Team from Azure DevOps

.DESCRIPTION
The command will retrieve members for the Azure DevOps teams specified 

.PARAMETER AzDoConnect
A valid AzDoConnection object

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.PARAMETER TeamName
The name of the build definition to retrieve (use on this OR the id parameter)

.EXAMPLE
Get-AzDoTeamMemebers -TeamName <name>

.EXAMPLE
Get-AzDoTeamMemebers -Teamid <id>
.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Get-AzDoTeamMemebers()
{
    [CmdletBinding(
        DefaultParameterSetName='ID'
    )]
    param
    (
        # Common Parameters
        [parameter(Mandatory=$false, ValueFromPipelinebyPropertyName=$true)][PoshAzDo.AzDoConnectObject]$AzDoConnection,
        [parameter(Mandatory=$false)][string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [parameter(Mandatory=$false, ParameterSetName="Name", ValueFromPipelineByPropertyName=$true)][Alias("name")][string]$TeamName,
        [parameter(Mandatory=$false, ParameterSetName="ID", ValueFromPipelineByPropertyName=$true)][Alias("id")][Guid]$TeamId
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

        if (-Not $ApiVersion.Contains("preview")) { $ApiVersion = "5.0-preview.2" }
        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0-preview.2"}


        if (-Not (Test-Path varaible:$AzDoConnection) -and $null -eq $AzDoConnection)
        {
            $AzDoConnection = Get-AzDoActiveConnection

            if ($null -eq $AzDoConnection) { Write-Error -ErrorAction $errorPreference -Message "AzDoConnection or ProjectUrl must be valid" }
        }

        if ([string]::IsNullOrEmpty($TeamName) -and [string]::IsNullOrEmpty($TeamId)) { Write-Error -ErrorAction $errorPreference -Message "Specify a Tean Name or Team ID" }

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
        Write-Verbose ($teams| ConvertTo-Json -Depth 50 | Out-String)
        Write-Verbose "---------TEAM MEMBERS---------"

        return $teams.value.identity
    }
    END 
    { 
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}

