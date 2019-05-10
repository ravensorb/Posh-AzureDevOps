function Get-AzDoHttpHeader()
{
    [CmdletBinding(
        DefaultParameterSetName="Specific" 
    )]
    param
    (
        # Common Parameters
        [PoshAzDo.AzDoConnectObject][parameter(ValueFromPipelinebyPropertyName = $true, ValueFromPipeline = $true, ParameterSetName="Connection")]$AzDoConnection,
        [string][parameter(ValueFromPipelinebyPropertyName = $true, ParameterSetName="Specific")]$ProjectUrl,
        [string][parameter(ValueFromPipelinebyPropertyName = $true, ParameterSetName="Specific")]$PAT,
        [string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [string][parameter(DontShow)]$OAuthToken
    )
    BEGIN
    {
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }        

        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0"}

        if (-Not (Test-Path varaible:$AzDoConnection) -and $AzDoConnection -eq $null)
        {
            if ([string]::IsNullOrEmpty($ProjectUrl))
            {
                throw "AzDoConnection or ProjectUrl must be valid"
            }
        }

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "`tParameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "`t`t$_ = '$($PSBoundParameters[$_])'" }

        if ($AzDoConnection -ne $null)
        {
            $ProjectUrl = $AzDoConnection.ProjectUrl
            $PAT = $AzDoConnection.PAT
        }
    }
    PROCESS
    {
        $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        # Base64-encodes the Personal Access Token (PAT) appropriately
        if (-Not [string]::IsNullOrEmpty($PAT)) {
            #Write-Verbose "Creating HTTP Auth Header for "
            $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes((":$PAT")))
            #Write-Verbose $base64AuthInfo
            $headers.Add("Authorization", ("Basic {0}" -f $base64AuthInfo))
        } 
        elseif (-Not [string]::IsNullOrEmpty($OAuthToken))
        {
            $headers.Add("Authorization", ("Bearer {0}" -f $OAuthToken))
        }

        #$headers.Add("Accept", "application/json;api-version=$($Apiversion)")
    
        #Write-Verbose $headers

        return $headers   
    }
    END
    {
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}