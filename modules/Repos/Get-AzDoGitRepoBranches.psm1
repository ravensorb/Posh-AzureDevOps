<#

.SYNOPSIS
Retrive branch information from the specified git repository

.DESCRIPTION
The command will retrieve a list of all branches from the specified git repository

.PARAMETER Name
The name of the git repository

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Get-AzDoGitRepoBranches -Name <git repo name>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Get-AzDoGitRepoBranches()
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
        [parameter(Mandatory=$false, ParameterSetName="Name")][string]$Name,
        [parameter(Mandatory=$false, ParameterSetName="ID")][Guid]$Id
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
        $repo = Get-AzDoGitRepos -AzDoConnection $AzDoConnection | ? { $_.name -eq $Name -or $_.id -eq $Id }

        if ($null -eq $repo)
        {
            Write-Error "Specified Repo Not Found..."

            return
        }

        $apiParams = @()

        $apiParams += "includeStatuses=True"
        $apiParams += "latestStatusesOnly=True"

        # GET https://dev.azure.com/{organization}/{project}/_apis/git/repositories/{repositoryId}/refs?api-version=5
        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.ProjectUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/git/repositories/$($repo.id)/refs" -QueryStringParams $apiParams

        $branches = Invoke-RestMethod $apiUrl -Headers $AzDoConnection.HttpHeaders 
        
        Write-Verbose "---------BRANCHES---------"
        Write-Verbose ($branches | ConvertTo-Json -Depth 50 | Out-String)
        Write-Verbose "---------BRANCHES---------"

        return $branches.value
    }
    END 
    { 
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}

