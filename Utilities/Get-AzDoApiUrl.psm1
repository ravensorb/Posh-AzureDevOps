function Get-AzDoApiUrl()
{
    [CmdletBinding()]
    param
    (
        [string][parameter(Mandatory = $true)]$ProjectUrl,
        [string][parameter(Mandatory = $true)]$BaseApiPath,
        [string]$QueryStringParams = $null,
        [string]$ApiVersion = $global:AzDoApiVersion
    )
    BEGIN
    {
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }        

        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0"}

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "Parameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "$_ = '$($PSBoundParameters[$_])'" }
    }
    PROCESS
    {
        $ProjectUrl = $ProjectUrl.TrimEnd("/")
        $BaseApiPath = $BaseApiPath.TrimStart("/")

        $apiUrl = "$($ProjectUrl)/$($BaseApiPath)?api-version=$($ApiVersion)"
        
        if (-Not [string]::IsNullOrEmpty($QueryStringParams))
        {
            $apiUrl = "$($apiUrl)&$($QueryStringParams)"
        }

        Write-Verbose "API Url: $apiUrl"

        return $apiUrl
    }
    END { }
}

