function Get-AzDoActiveConnection()
{
    [OutputType([PoshAzDo.AzDoConnectObject])]
    [CmdletBinding()]
    param
    (
    )
    BEGIN
    {
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }        

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "`tParameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "`t`t$_ = '$($PSBoundParameters[$_])'" }
    }
    PROCESS
    {
        Write-Verbose "Checking to see if there is an active AzDo connection"
        if (-Not (Test-Path variable:global:AzDoActiveConnection))
        {
            Write-Error "No validation connection found.  Please call the Connect-AzDo function"

            return $null
        }

        Write-Verbose "`tActive Connection for: $($Global:AzDoActiveConnection.ProjectUrl)"
        
        $global:AzDoActiveConnection
    }
    END
    {

    }
}