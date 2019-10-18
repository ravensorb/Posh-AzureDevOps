<#

.SYNOPSIS
Remove a git repository

.DESCRIPTION
The command will remove a specific git repository

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Remove-AzDoGitRepo -Name <git repo name>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Remove-AzDoGitRepo()
{
    [CmdletBinding(
        SupportsShouldProcess=$True
    )]
    param
    (
        # Common Parameters
        [PoshAzDo.AzDoConnectObject][parameter(ValueFromPipelinebyPropertyName = $true, ValueFromPipeline = $true)]$AzDoConnection,
        [string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [string][parameter()]$Name
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

        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.1"}

        if (-Not (Test-Path varaible:$AzDoConnection) -and $AzDoConnection -eq $null)
        {
            $AzDoConnection = Get-AzDoActiveConnection

            if ($null -eq $AzDoConnection) { Write-Error -ErrorAction $errorPreference -Message "AzDoConnection or ProjectUrl must be valid" }
        }

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "Parameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "$_ = '$($PSBoundParameters[$_])'" }
    }
    PROCESS
    {
        $repo = Get-AzDoGitRepos -AzDoConnection $AzDoConnection | ? { $_.name -eq $Name }
        if ($null -eq $repo)
        {
            Write-Error "Requested Git Repository does not exist: $($repo)"

            return
        }

        $apiParams = @()

        # DELETE https://dev.azure.com/{organization}/{project}/_apis/git/repositories/{repositoryId}?api-version=5.1
        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.ProjectUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/git/repositories/$($repo.id)" -QueryStringParams $apiParams

        if (-Not $WhatIfPreference)
        {
            $response = Invoke-RestMethod $apiUrl -Method DELETE -ContentType 'application/json' -Header $($AzDoConnection.HttpHeaders)    
        }
        
        Write-Verbose "---------Repos---------"
        Write-Verbose ($results | ConvertTo-Json -Depth 50 | Out-String)
        Write-Verbose "---------Repos---------"

        return $response
    }
    END {
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
     }
}

