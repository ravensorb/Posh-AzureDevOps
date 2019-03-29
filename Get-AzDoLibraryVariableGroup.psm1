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
        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0-preview.1"}

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "Parameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "$_ = '$($PSBoundParameters[$_])'" }
    }
    PROCESS
    {
        $headers = Get-AzDoHttpHeader -PAT $PAT -ApiVersion $ApiVersion 

        $ProjectUrl = $ProjectUrl.TrimEnd("/")
        $url = "$($ProjectUrl)/_apis/distributedtask/variablegroups?api-version=$($ApiVersion)"
        $variableGroups = Invoke-RestMethod $url -Headers $headers
        
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
