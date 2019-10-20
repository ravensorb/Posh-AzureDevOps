<#

.SYNOPSIS
This command provides remove a Security Group from Azure DevOps

.DESCRIPTION
The command will remove an Azure DevOps Security Group

.PARAMETER AzDoConnect
A valid AzDoConnection object

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.PARAMETER GroupId
The id of the group to remove

.PARAMETER GroupName
The name of the group to remove

.EXAMPLE
Remove-AzDoSecurityGroup -GroupName <group name>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Remove-AzDoSecurityGroup()
{
    [CmdletBinding(
        DefaultParameterSetName="Name",
        SupportsShouldProcess=$True
    )]
    param
    (
        # Common Parameters
        [parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelinebyPropertyName=$true)][PoshAzDo.AzDoConnectObject]$AzDoConnection,
        [parameter(Mandatory=$false)][string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [parameter(Mandatory=$false, ValueFromPipelinebyPropertyName=$true, ParameterSetName = "Name")][string]$GroupName
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

        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.2-preview.1" }
        if (-Not $ApiVersion.Contains("preview")) { $ApiVersion = "5.2-preview.1" }

        if (-Not (Test-Path varaible:$AzDoConnection) -and $null -eq $AzDoConnection)
        {
            $AzDoConnection = Get-AzDoActiveConnection

            if ($null -eq $AzDoConnection) { Write-Error -ErrorAction $errorPreference -Message "AzDoConnection or ProjectUrl must be valid" }
        }

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "`tParameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "`t`t$_ = '$($PSBoundParameters[$_])'" }        
    }
    PROCESS
    {
        $groups = Get-AzDoSecurityGroups -AzDoConnection $AzDoConnection
        $group = $groups | ? { $_.displayName -like $GroupName -or $_.principalName -like $GroupName} 

        if (-Not $group)
        {
            Write-Error -ErrorAction $errorPreference -Message "Team specified was not found"
        }

        $apiParams = @()

        # DELETE https://vssps.dev.azure.com/{organization}/_apis/graph/groups/{groupDescriptor}?api-version=5.0-preview.1

        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.VsspUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/graph/groups/$($group.descriptor)" -QueryStringParams $apiParams

        if (-Not $WhatIfPreference)
        {
            $response =  Invoke-RestMethod $apiUrl -Method DELETE -ContentType 'application/json' -Header $($AzDoConnection.HttpHeaders)            
        }

        Write-Verbose "---------RESPONSE---------"
        Write-Verbose ($response| ConvertTo-Json -Depth 50 | Out-String)
        Write-Verbose "---------RESPONSE---------"
    }
    END 
    { 
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}

