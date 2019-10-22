<#

.SYNOPSIS
Resets a specific Azure DevOps Variable Group

.DESCRIPTION
The command will clear our an azure DevOps Variable grou

.PARAMETER VariableGroupName
The name of the variable group to create/update (optional)

.PARAMETER VariableGroupId
A id for the variable group (optional)

.PARAMETER InitalVariableName
Tha name of the variable to create/update

.PARAMETER InitalVariableValue
The variable for the variable

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Reset-AzDoVariableGroup -VariableGroupName <variable group name> -InitalVariableName <variable name> -InitalVariableValue <some value>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Reset-AzDoVariableGroup()
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
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)][string]$InitalVariableName = "CreatedOn",
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)][string]$InitalVariableValue = (Get-Date).ToString(),
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)][bool]$Secret
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
        $method = "POST"

        if ([string]::IsNullOrEmpty($VariableGroupName) -and [string]::IsNullOrEmpty($VariableGroupId))
        {
            Write-Error -ErrorAction $errorPreference -Message "Specify either Variable Group Name or Variable Group Id"

            return
        }

        $variableGroup = Get-AzDoVariableGroups -AzDoConnection $AzDoConnection | ? { $_.name -eq $VariableGroupName -or $_.id -eq $VariableGroupId }

        if ($null -eq $variableGroup)
        {
            Write-Error -ErrorAction $errorPreference -Message "Specified variabl group '$($VariableGroupName) does not exist..."

            return
        }

        Write-Verbose "Variable group $VariableGroupName exists."

        Write-Verbose "Reset = $Reset : remove all variables."
        foreach($prop in $variableGroup.variables.PSObject.Properties.Where{$_.MemberType -eq "NoteProperty"})
        {
            $variableGroup.variables.PSObject.Properties.Remove($prop.Name)
        }

        Write-Verbose "Adding $VariableName with value $VariableValue..."
        $variableGroup.variables | Add-Member -Name $InitalVariableName -MemberType NoteProperty -Value @{value=$InitalVariableValue;isSecret=$Secret} -Force

        #Write-Verbose "Persist variable group $VariableGroupName."
        $body = $variableGroup | ConvertTo-Json -Depth 50 -Compress

        Write-Verbose "---------BODY---------"
        Write-Verbose $body
        Write-Verbose "---------BODY---------"

        if (-Not $WhatIfPreference) 
        {
            $response = Invoke-RestMethod $apiUrl -Method $method -Body $body -ContentType 'application/json' -Header $($AzDoConnection.HttpHeaders)
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
