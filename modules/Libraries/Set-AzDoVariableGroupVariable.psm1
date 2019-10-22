<#

.SYNOPSIS
Add/Replace a new variable to a specific Azure DevOps libary

.DESCRIPTION
The command will add/replace a variable to the specificed variable group

.PARAMETER VariableGroupName
The name of the variable group to create/update (optional)

.PARAMETER VariableGroupId
A id for the variable group (optional)

.PARAMETER VariableName
Tha name of the variable to create/update

.PARAMETER VariableValue
The variable for the variable

.PARAMETER Secret
Indicates if the vaule should be stored as a "secret"

.PARAMETER Reset
Indicates if the ENTIRE variable group should be reset. This means that ALL values are REMOVED. Use with caution

.PARAMETER Force
Indicates if the variable group should be created if it doesn't exist

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Set-AzDoVariableGroupVariable -VariableGroupName <variable group name> -VariableName <variable name> -VariableValue <some value>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Set-AzDoVariableGroupVariable()
{
    [CmdletBinding(
        SupportsShouldProcess=$True
    )]
    param
    (
        # Common Parameters
        [parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelinebyPropertyName=$true)][PoshAzDo.AzDoConnectObject]$AzDoConnection,
        [parameter(Mandatory=$false)][string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [parameter(Mandatory=$true, ValueFromPipelinebyPropertyName=$true, ParameterSetName="Name")][string]$VariableGroupName,
        [parameter(Mandatory=$true, ValueFromPipelinebyPropertyName=$true, ParameterSetName="ID")][string]$VariableGroupId,

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)][string]$VariableName,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)][string]$VariableValue,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)][bool]$Secret,

        [parameter(Mandatory=$false)][switch]$Force
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
    
        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0-preview.1" }
        if (-Not $ApiVersion.Contains("preview")) { $ApiVersion = "5.0-preview.1" }

        if (-Not (Test-Path varaible:$AzDoConnection) -and $null -eq $AzDoConnection)
        {
            $AzDoConnection = Get-AzDoActiveConnection

            if ($null -eq $AzDoConnection) { Write-Error -ErrorAction $errorPreference -Message "AzDoConnection or ProjectUrl must be valid" }
        }

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "Parameter Values"

        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "$_ = '$($PSBoundParameters[$_])'" }
    }
    PROCESS
    {
        if ([string]::IsNullOrEmpty($VariableGroupName) -and [string]::IsNullOrEmpty($VariableGroupId))
        {
            Write-Error -ErrorAction $errorPreference -Message "Specify either Variable Group Name or Variable Group Id"
        }

        $variableGroup = Get-AzDoVariableGroups -AzDoConnection $AzDoConnection | ? { $_.name -eq $VariableGroupName -or $_.id -eq $VariableGroupId }

        if($null -eq $variableGroup)
        {
            Write-Error "Variable group '$VariableGroupName' not found."

            return
        }

        $variable = $variableGroup.variables.PSObject.Properties | ? { $_.name -eq $VariableName }

        if ($null -ne $variable)
        {
            $variable.value = $VariableValue
        }
        else 
        {
            if (-Not $Force)
            {
                Write-Error -ErrorAction $errorPreference -Message "Variable '$VariableName' not found."

                return
            }

            $variableGroup.variables | Add-Member -Name $VariableName -MemberType NoteProperty -Value @{value=$VariableValue;isSecret=$Secret} -Force

        }

        #Write-Verbose "Persist variable group $VariableGroupName."
        $body = $variableGroup | ConvertTo-Json -Depth 50 -Compress

        Write-Verbose "---------BODY---------"
        Write-Verbose $body
        Write-Verbose "---------BODY---------"

        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.ProjectUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/distributedtask/variablegroups/$($variableGroup.id)"

        if (-Not $WhatIfPreference) 
        {
            $response = Invoke-RestMethod $apiUrl -Method PUT -Body $body -ContentType 'application/json' -Header $($AzDoConnection.HttpHeaders)
        }
        
        Write-Verbose "---------RESPONSE---------"
        Write-Verbose ($response | ConvertTo-Json -Depth 50 | Out-String)
        Write-Verbose "---------RESPONSE---------"

        $response
    }
    END
    {
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}
