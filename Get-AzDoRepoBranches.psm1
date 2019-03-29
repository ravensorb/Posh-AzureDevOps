function Get-AzDoRepoBranches()
{
    [CmdletBinding()]
    param
    (
        [string][parameter(Mandatory = $true)]$ProjectUrl,
        [string]$Name,
        [string]$PAT,
        [string]$ApiVersion = $global:AzDoApiVersion
    )
    BEGIN
    {
       if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0"}

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "Parameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "$_ = '$($PSBoundParameters[$_])'" }
    }
    PROCESS
    {
        $headers = Get-AzDoHttpHeader -PAT $PAT -ApiVersion $ApiVersion 

        # GET https://dev.azure.com/{organization}/{project}/_apis/git/repositories/{repositoryId}/refs?api-version=5
        $url = "$($ProjectUrl)/_apis/git/repositories/$Name/refs?includeStatuses=True&latestStatusesOnly=True&api-version=$($ApiVersion)"

        $branches = Invoke-RestMethod $url -Headers $headers 
        
        Write-Verbose $branches

        return $branches.value
    }
    END { }
}

