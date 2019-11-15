<#

.SYNOPSIS
Add permission for a specific Azure DevOps libary

.DESCRIPTION
The command will add the permissions for the specificed variable group

.PARAMETER VariableGroupName
The name of the variable group to retrieve

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Add-AzDoVariableGroupResourceAssignment -VariableGroupName <variable group name>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Add-AzDoVariableGroupResourceAssignment()
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
        [parameter(Mandatory=$true, ValueFromPipelinebyPropertyName=$true, ParameterSetName="Name")][string][Alias("name")]$VariableGroupName,
        [parameter(Mandatory=$true, ValueFromPipelinebyPropertyName=$true, ParameterSetName="ID")][int][Alias("id")]$VariableGroupId,

        [parameter(Mandatory=$true, ValueFromPipelinebyPropertyName=$true)][string]$RoleName,
        [parameter(Mandatory=$true, ValueFromPipelinebyPropertyName=$true)][string]$UserOrGroupName
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
    
        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.1-preview" }
        if (-Not $ApiVersion.Contains("preview")) { $ApiVersion = "5.1-preview" }

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
            return
        }

        $variableGroup = Get-AzDoVariableGroups -AzDoConnection $AzDoConnection | ? { $_.name -like $VariableGroupName -or $_.id -eq $VariableGroupId }

        if ($null -eq $variableGroup)
        {
            Write-Error -ErrorAction $errorPreference -Message "Variable Group '[$($VariableGroupId)]:$($VariableGroupName)' not found"
            return
        }

        # If we already have a project qualified query string lets just use that
        if ($UserOrGroupName.StartsWith("["))
        {
            $userOrGroup = Get-AzDoIdentities -AzDoConnection $AzDoConnection -QueryString "$UserOrGroupName"
        }
        else 
        {
            $userOrGroup = Get-AzDoIdentities -AzDoConnection $AzDoConnection -QueryString "[$($AzDoConnection.ProjectName)]\$UserOrGroupName"
        }

        if ($null -eq $userOrGroup)
        {
            Write-Error -ErrorAction $errorPreference -Message "User/Group/Team '$UserOrGroupName' not found"
            return
        }

        # PUT https://<acct>.visualstudio.com/_apis/securityroles/scopes/distributedtask.variablegroup/roleassignments/resources/<projID>$<VarGroupID>?api-version=5.0-preview.1
        # [{"roleName":"<role>","userId":",<UserGUID>"}]
        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.OrganizationUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/securityroles/scopes/distributedtask.variablegroup/roleassignments/resources/$($AzDoConnection.ProjectId)`$$($variableGroup.Id)"

        $body = "[{`"roleName`":`"$($RoleName)`",`"userId`":`"$($userOrGroup.originId)`"}]"
        # $roleDetails = @()
        # $roleDetails += @{roleName=$RoleName;userId=$($userOrGroup.originId)}
        # $body = $roleDetails | ConvertTo-Json -Depth 50 -Compress

        Write-Verbose "---------BODY---------"
        Write-Verbose $body
        Write-Verbose "---------BODY---------"

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
