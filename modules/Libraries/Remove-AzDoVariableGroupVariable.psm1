<#

.SYNOPSIS
Remove a variable from a specific Azure DevOps libary

.DESCRIPTION
The  command will remove a variable to the specificed variable group

.PARAMETER VariableGroupName
The name of the variable group to create/update

.PARAMETER VariableName
Tha name of the variable to create/update

.PARAMETER All
Remove all variables in the variable group (VariableName is ignored when this is set)

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Remove-AzDoVariableGroupVariable -VaraibleGroupName <name of variable group> -VariableName <variable name>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Remove-AzDoVariableGroupVariable()
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
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName="id")][int]$VariableGroupId,
        [parameter(Mandatory=$false, ValueFromPipelinebyPropertyName=$true)][string]$VariableName,
        [parameter(Mandatory=$false)][switch]$All
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

        if (-Not (Test-Path varaible:$AzDoConnection) -and $AzDoConnection -eq $null)
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

        if(-Not $variableGroup)
        {
            Write-Error -ErrorAction $errorPreference -Message "Cannot add variable to nonexisting variable group $VariableGroupName; use the -Force switch to create the variable group."

        }

        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.ProjectUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/distributedtask/variablegroups/$($variableGroup.id)"

        Write-Verbose "Variable group $VariableGroupName exists."

        [bool]$found = $false
        foreach($prop in $variableGroup.variables.PSObject.Properties.Where{$_.MemberType -eq "NoteProperty" -and (($_.Name -eq $VariableName) -or $All)})
        {
            Write-Verbose "Removing variable: $($prop.Name)"

            $variableGroup.variables.PSObject.Properties.Remove($prop.Name)

            $found = $true
        }

        if (-Not $found)
        {
            Write-Verbose "Variable not found"

            return
        }

        #Write-Verbose "Persist variable group $VariableGroupName."
        $body = $variableGroup | ConvertTo-Json -Depth 50 -Compress

        Write-Verbose "---------BODY---------"
        Write-Verbose $body
        Write-Verbose "---------BODY---------"

        #Write-Verbose $body
        if (-Not $WhatIfPreference) 
        {
            $response = Invoke-RestMethod $apiUrl -Method Put -Body $body -ContentType 'application/json' -Header $($AzDoConnection.HttpHeaders)
        }
        
        Write-Verbose "---------RESPONSE---------"
        Write-Verbose ($response | ConvertTo-Json -Depth 50 | Out-String)
        Write-Verbose "---------RESPONSE---------"

        #$response
    }
    END
    {
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}
