function Get-AzDoRmReleaseDefinition()
{
    [CmdletBinding()]
    param
    (
        [string][parameter(Mandatory = $true)]$ProjectUrl,
        [string]$Name,
        [int]$Id,
        [string]$PAT
    )
    BEGIN
    {
        if (-Not (Test-Path variable:global:AzDoApiVersion)) { $global:AzDoApiVersion = "5.0"}
        if ($Id -eq $null -and [string]::IsNullOrEmpty($Name)) { Write-Error "Definition ID or Name must be specified"; Exit;}

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "Parameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "$_ = '$($PSBoundParameters[$_])'" }
    }
    PROCESS
    {
        $headers = Get-AzDoHttpHeader -PAT $PAT 

        $ProjectUrl = Get-AzDoRmUrlFromProjectUrl $ProjectUrl

        if ($Id -ne $null -and $Id -ne 0) 
        {
            $url = "$($ProjectUrl)/_apis/release/definitions/$($Id)?api-version=$($global:AzDoApiVersion)"
        }
        else 
        {
            $url = "$($ProjectUrl)/_apis/release/definitions?api-version=$($global:AzDoApiVersion)&searchText=$Name"
        }

        $releaseDefinitions = Invoke-RestMethod $url -Headers $headers 
        
        Write-Verbose $releaseDefinitions

        if ($releaseDefinitions.count -ne $null)
        {
            foreach($rd in $releaseDefinitions.value)
            {
                if ($rd.name -like $Name){
                    Write-Verbose "Release Defintion Found $($rd.name) found."

                    return $rd
                }
            }
            Write-Verbose "Release definition $Name not found."
        } 
        elseif ($releaseDefinitions -ne $null) {
            return $releaseDefinitions
        }

        Write-Verbose "Release definition $Id not found."
        
        return $null
    }
    END { }
}

