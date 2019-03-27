function Get-AzDoBuildDefinition()
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

        if ($Id -ne $null -and $Id -ne 0) 
        {
            $url = "$($ProjectUrl)/_apis/build/definitions/$($Id)?api-version=$($global:AzDoApiVersion)"
        }
        else 
        {
            $url = "$($ProjectUrl)/_apis/build/definitions?api-version=$($global:AzDoApiVersion)&searchText=$Name"
        }

        $buildDefinitions = Invoke-RestMethod $url -Headers $headers 
        
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

