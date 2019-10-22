<#

.SYNOPSIS
This command provides creates a new Team for Azure DevOps

.DESCRIPTION
The command will create a new Azure DevOps Team

.PARAMETER AzDoConnect
A valid AzDoConnection object

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.PARAMETER TeamName
The name of the group to create

.PARAMETER TeamDescription
The description of the group to create

.EXAMPLE
Create-AzDoTeam -TeamName <team name>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function New-AzDoTeam()
{
    [CmdletBinding(
        DefaultParameterSetName="Name",
        SupportsShouldProcess=$True
    )]
    param
    (
        # Common Parameters
        [parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelinebyPropertyName=$true)][PoshAzDo.AzDoConnectObject]$AzDoConnection,
        [parameter(Mandatory=$false)][string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [parameter(Mandatory=$false, ValueFromPipelinebyPropertyName=$true)][string]$TeamName,
        [parameter(Mandatory=$false)][string]$TeamDescription
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

        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0"}

        if (-Not (Test-Path varaible:$AzDoConnection) -and $null -eq $AzDoConnection)
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

        # POST https://dev.azure.com/{organization}/_apis/projects/{projectId}/teams?api-version=5.0
        # {
        #    "name": "Team Name",
        # }
        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.OrganizationUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/projects/$($AzDoConnection.ProjectName)/teams" -QueryStringParams $apiParams
        $teamDetails = @{name=$TeamName; description=$TeamDescription}
        $body = $teamDetails | ConvertTo-Json -Depth 50 -Compress

        Write-Verbose "---------BODY---------"
        Write-Verbose $body
        Write-Verbose "---------BODY---------"

        if (-Not $WhatIfPreference)
        {
            $team = Invoke-RestMethod $apiUrl -Method POST -Body $body -ContentType 'application/json' -Header $($AzDoConnection.HttpHeaders)    
        }
        
        Write-Verbose "---------TEAM---------"
        Write-Verbose ($team| ConvertTo-Json -Depth 50 | Out-String)
        Write-Verbose "---------TEAM---------"

        $team
    }
    END 
    { 
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}

