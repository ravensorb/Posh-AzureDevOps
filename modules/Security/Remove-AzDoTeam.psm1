<#

.SYNOPSIS
This command provides remove a Team for Azure DevOps

.DESCRIPTION
The command will remove an Azure DevOps Team

.PARAMETER AzDoConnect
A valid AzDoConnection object

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.PARAMETER TeamId
The id of the group to remove

.PARAMETER TeamName
The name of the group to remove

.EXAMPLE
Remove-AzDoTeam -TeamName <team name>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Remove-AzDoTeam()
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
        [parameter(Mandatory=$false, ParameterSetName = "Id", ValueFromPipelinebyPropertyName=$true)][Guid]$TeamId,
        [parameter(Mandatory=$false, ParameterSetName = "Name")][string]$TeamName
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
        $team = Get-AzDoTeams -AzDoConnection $AzDoConnection | Where-Object { $_.id -eq $TeamId -or (-Not [string]::IsNullOrEmpty($TeamName) -and $_.name -like $TeamName) }

        if (-Not $team)
        {
            Write-Error "Team $TeamId $TeamName specified was not found"

            return
        }

        $apiParams = @()

        # DELETE https://dev.azure.com/{organization}/_apis/projects/{projectId}/teams/{teamId}?api-version=5.0

        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.OrganizationUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/projects/$($AzDoConnection.ProjectName)/teams/$($team.Id)" -QueryStringParams $apiParams

        if (-Not $WhatIfPreference)
        {
            $result = Invoke-RestMethod $apiUrl -Method DELETE -ContentType 'application/json' -Header $($AzDoConnection.HttpHeaders)     
        }
        
        Write-Verbose "---------RESULT---------"
        Write-Verbose ($result | ConvertTo-Json -Depth 50 | Out-String)
        Write-Verbose "---------RESULT---------"

        Write-Verbose "Removed $($team.displayName)"

        $true
    }
    END 
    { 
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}

