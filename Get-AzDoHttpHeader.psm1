function Get-AzDoHttpHeader()
{
    [CmdletBinding()]
    param
    (
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
        $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        # Base64-encodes the Personal Access Token (PAT) appropriately
        if (-Not [string]::IsNullOrEmpty($PAT)) {
            Write-Verbose "Creating HTTP Auth Header for PAT"
            $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes((":$PAT")))
            Write-Verbose $base64AuthInfo
            $headers.Add("Authorization", ("Basic {0}" -f $base64AuthInfo))
        }
        $headers.Add("Accept", "application/json;api-version=$($Apiversion)")
    
        Write-Verbose $headers

        return $headers   
    }
    END
    {

    }
}