<#

.SYNOPSIS
Add a new git repostiory

.DESCRIPTION
The command will add a new git repositories

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
New-AzDoGitRepo -Name <git repo name>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function New-AzDoGitRepo()
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
        $apiParams = @()

        # POST https://dev.azure.com/{organization}/{project}/_apis/git/repositories?api-version=5.1
        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.ProjectUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/git/repositories" -QueryStringParams $apiParams

        # {
        #   "name": "AnotherRepository",
        #   "project": {
        #     "id": "6ce954b1-ce1f-45d1-b94d-e6bf2464ba2c"
        #   }
        # }
        $data = @{name=$Name;project=@{id=$AzDoConnection.ProjectId}}
        $body = $data | ConvertTo-Json -Depth 10 -Compress

        Write-Verbose "---------Request---------"
        Write-Verbose $body
        Write-Verbose "---------Reqest---------"

        if (-Not $WhatIfPreference)
        {
            $response = Invoke-RestMethod $apiUrl -Method POST -Body $body -ContentType 'application/json' -Header $($AzDoConnection.HttpHeaders)    
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

