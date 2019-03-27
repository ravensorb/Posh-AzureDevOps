function Get-AzDoRmUrlFromProjectUrl()
{
    [CmdletBinding()]
    param
    (
        [string][parameter(Mandatory = $true)]$ProjectUrl
    )
    BEGIN
    {
        if (-Not (Test-Path variable:global:AzDoApiVersion)) { $global:AzDoApiVersion = "5.0"}

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "Parameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "$_ = '$($PSBoundParameters[$_])'" }
    }
    PROCESS
    {
        $ProjectUrl = $ProjectUrl.TrimEnd("/")

        if (-Not $ProjectUrl.Contains("vsrm."))
        {
            #Write-Verbose "Updating Project URL"
            if ($ProjectUrl.Contains(".visualstudio.com"))
            {
                #Write-Verbose "Setting Visual Studio Version"
                $ProjectUrl = $ProjectUrl.Replace(".visualstudio.com", ".vsrm.visualstudio.com")
            }
            elseif ($ProjectUrl.Contains("dev.azure.com"))
            {
                #Write-Verbose "Setting Azure Version"
                $ProjectUrl = $ProjectUrl.Replace("dev.azure.com", "vsrm.dev.azure.com")
            }
            else 
            {
                # Looks like this is invalid so lets return a null result
                $ProjectUrl = $null
            }
        }

        $ProjectUrl
    }
    END { }    
}