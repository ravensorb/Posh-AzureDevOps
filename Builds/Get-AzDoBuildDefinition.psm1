function Get-AzDoBuildDefinition()
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

        $apiUrl = Get-AzDoApiUrl -ProjectUrl $ProjectUrl -BaseApiPath "/_apis/build/definitions"
    }
    PROCESS
    {
        if ($Id -ne $null -and $Id -ne 0) 
        {
            $apiUrl = Get-AzDoApiUrl -ProjectUrl $ProjectUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/build/definitions/$($Id)"
        }
        else 
        {
            $apiUrl = Get-AzDoApiUrl -ProjectUrl $ProjectUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/build/definitions" -QueryStringParams "searchText=$($Name)"
        }

        $buildDefinitions = Invoke-RestMethod $apiUrl -Headers $headers
        
        Write-Verbose $buildDefinitions

        if ($buildDefinitions.count -ne $null)
        {
            foreach($bd in $buildDefinitions.value)
            {
                if ($bd.name -like $Name){
                    Write-Verbose "Release Defintion Found $($bd.name) found."

                    return $bd
                }
            }
            Write-Verbose "Build definition $Name not found."
        } 
        elseif ($buildDefinitions -ne $null) {
            return $buildDefinitions
        }

        Write-Verbose "Build definition $Id not found."
        
        return $null
    }
    END { }
}

