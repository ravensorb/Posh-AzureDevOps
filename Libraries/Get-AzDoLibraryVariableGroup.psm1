function Get-AzDoLibraryVariableGroup()
{
    [CmdletBinding()]
    param
    (
        [string][parameter(Mandatory = $true)]$ProjectUrl,
        [string][parameter(Mandatory = $true)]$Name,
        [string]$PAT,
        [string]$ApiVersion
    )
    BEGIN
    {
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }        
    
        if (-Not $ApiVersion.Contains("preview")) { $ApiVersion = $null }
        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0-preview.1"}

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "Parameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "$_ = '$($PSBoundParameters[$_])'" }

        $headers = Get-AzDoHttpHeader -PAT $PAT -ApiVersion $ApiVersion

        $apiUrl = Get-AzDoApiUrl -ProjectUrl $ProjectUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/distributedtask/variablegroups"
    }
    PROCESS
    {
        $variableGroups = Invoke-RestMethod $apiUrl -Headers $headers
        
        Write-Verbose $variableGroups

        foreach($variableGroup in $variableGroups.value){
            if ($variableGroup.name -like $Name){
                Write-Verbose "Variable group $Name found."
                return $variableGroup
            }
        }
        Write-Verbose "Variable group $Name not found."
        return $null
    }
    END { }
}
