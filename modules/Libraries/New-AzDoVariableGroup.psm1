<#

.SYNOPSIS
Create a new Variable Group

.DESCRIPTION
The command will create a new variable group

.PARAMETER VariableGroupName
The name of the variable group to retrieve

.PARAMETER Description
A description for this variable group

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
New-AzDoVariableGroup -VariableGroupName <variable group name>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function New-AzDoVariableGroup()
{
    [CmdletBinding(
        SupportsShouldProcess=$True
    )]
    param
    (
        # Common Parameters
        [PoshAzDo.AzDoConnectObject][parameter(ValueFromPipelinebyPropertyName = $true, ValueFromPipeline = $true)]$AzDoConnection,
        [string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [string][parameter(Mandatory = $true, ValueFromPipelinebyPropertyName = $true)]$VariableGroupName,
        [string]$Description
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
        $method = "Post"

        $variableGroup = Get-AzDoVariableGroups -AzDoConnection $AzDoConnection | ? { $_.name -eq $VariableGroupName }

        if ($variableGroup) 
        {
            Write-Verbose "Variable group $VariableGroupName exists"

            return $variableGroup
        }

        Write-Verbose "Variable group $VariableGroupName not found."

        Write-Verbose "Create variable group $VariableGroupName."

        $variableGroup = @{name=$VariableGroupName;description=$Description;variables=New-Object PSObject;}
        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.ProjectUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/distributedtask/variablegroups"

        $variableGroup.variables | Add-Member -Name "NewVariable1" -MemberType NoteProperty -Value @{value="";isSecret=$false} -Force

        #Write-Verbose "Persist variable group $VariableGroupName."
        $body = $variableGroup | ConvertTo-Json -Depth 10 -Compress

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
