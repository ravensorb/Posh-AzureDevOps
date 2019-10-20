function Get-AzDoHttpHeader()
{
    [CmdletBinding(
        DefaultParameterSetName="Specific" 
    )]
    param
    (
        # Common Parameters
        [parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelinebyPropertyName=$true)][PoshAzDo.AzDoConnectObject]$AzDoConnection,
        [parameter(Mandatory=$false)][string]$ApiVersion = $global:AzDoApiVersion,
        [parameter(Mandatory=$false, ValueFromPipelinebyPropertyName=$true, ParameterSetName="Specific")][string]$ProjectUrl,
        [parameter(Mandatory=$false, ValueFromPipelinebyPropertyName=$true, ParameterSetName="Specific")][string]$PAT,

        # Module Parameters
        [parameter(Mandatory=$false, DontShow)][string]$OAuthToken
    )
    BEGIN
    {
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }  

        $errorPreference = 'Stop'
        if ( $PSBoundParameters.ContainsKey('ErrorAction')) {
            $errorPreference = $PSBoundParameters['ErrorAction']
        }

        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0"}

        if (-Not (Test-Path varaible:$AzDoConnection) -and $null -eq $AzDoConnection)
        {
            if ([string]::IsNullOrEmpty($ProjectUrl))
            {
                Write-Error -ErrorAction $errorPreference -Message "AzDoConnection or ProjectUrl must be valid"
            }
        }

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "`tParameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "`t`t$_ = '$($PSBoundParameters[$_])'" }

        if ($null -ne $AzDoConnection)
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
        $headers.Add("Accept", "application/json")
    
        #Write-Verbose $headers

        return $headers   
    }
    END
    {
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}