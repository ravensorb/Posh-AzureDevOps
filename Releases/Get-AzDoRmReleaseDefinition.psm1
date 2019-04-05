function Get-AzDoRmReleaseDefinition()
{
    [CmdletBinding()]
    param
    (
        [string][parameter(Mandatory = $true)]$ProjectUrl,
        [string]$Name,
        [int]$Id,
        [string]$PAT,
        [string]$ApiVersion = $global:AzDoApiVersion
    )
    BEGIN
    {
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }        

        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0"}

        if ($Id -eq $null -and [string]::IsNullOrEmpty($Name)) { Write-Error "Definition ID or Name must be specified"; Exit;}

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "Parameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "$_ = '$($PSBoundParameters[$_])'" }

        $headers = Get-AzDoHttpHeader -PAT $PAT -ApiVersion $ApiVersion 

        $ProjectUrl = Get-AzDoRmUrlFromProjectUrl $ProjectUrl      
    }
    PROCESS
    {
        if ($Id -ne $null -and $Id -ne 0) 
        {
            $apiUrl = Get-AzDoApiUrl -ProjectUrl $ProjectUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/release/definitions/$($Id)"
        }
        else 
        {
            $apiUrl = Get-AzDoApiUrl -ProjectUrl $ProjectUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/release/definitions" -QueryStringParams "searchText=$Name"
        }

        $releaseDefinitions = Invoke-RestMethod $apiUrl -Headers $headers 
        
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

