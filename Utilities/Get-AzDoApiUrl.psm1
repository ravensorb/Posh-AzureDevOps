function Get-AzDoApiUrl()
{
    [CmdletBinding()]
    param
    (
        [string][parameter(Mandatory = $true, ValueFromPipelinebyPropertyName = $true)]$ProjectUrl,
        [string][parameter(Mandatory = $true)]$BaseApiPath,
        [string[]]$QueryStringParams = $null,
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
        Write-Verbose "`tParameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "`t`t$_ = '$($PSBoundParameters[$_])'" }
    }
    PROCESS
    {
        $ProjectUrl = $ProjectUrl.TrimEnd("/")
        $BaseApiPath = $BaseApiPath.TrimStart("/")

        $apiUrl = "$($ProjectUrl)/$($BaseApiPath)?api-version=$($ApiVersion)"
        
        if ($QueryStringParams) {
            foreach ($q in $QueryStringParams) {
                $apiUrl = "$($apiUrl)&$($q)"
            }
        }
        
        Write-Verbose "API Url: $apiUrl"

        return $apiUrl
    }
    END { }
}

