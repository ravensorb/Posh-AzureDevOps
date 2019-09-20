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
        DefaultParameterSetName="Name"
    )]
    param
    (
        # Common Parameters
        [PoshAzDo.AzDoConnectObject][parameter(ValueFromPipelinebyPropertyName = $true, ValueFromPipeline = $true)]$AzDoConnection,
        [string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [string][parameter(ValueFromPipelinebyPropertyName = $true, ParameterSetName="Name")][Alias("name")]$VariableGroupName,
        [int][parameter(ValueFromPipelinebyPropertyName = $true, ParameterSetName="ID")][Alias("id")]$VariableGroupId,

        [string][parameter(ValueFromPipelinebyPropertyName = $true)]$RoleName,
        [string][parameter(ValueFromPipelinebyPropertyName = $true)]$UserOrGroupName
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

        if (-Not (Test-Path varaible:$AzDoConnection) -and $AzDoConnection -eq $null)
        {
            $AzDoConnection = Get-AzDoActiveConnection

            if ($AzDoConnection -eq $null) { Write-Error -ErrorAction $errorPreference -Message "AzDoConnection or ProjectUrl must be valid" }
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

        $variableGroup = Get-AzDoVariableGroups -AzDoConnection $AzDoConnection | ? { $_.name -clike $VariableGroupName -or $_.id -eq $VariableGroupId }

        if ($variableGroup -eq $null)
        {
            Write-Error -ErrorAction $errorPreference -Message "Variable Group '[$($VariableGroupId)]:$($VariableGroupName)' not found"
        }

        $userOrGroup = Get-AzDoSecurityGroups -AzDoConnection $AzDoConnection | ? { $_.displayName -eq $UserOrGroupName -or $_.principalName -eq $UserOrGroupName}
        if ($userOrGroup -eq $null)
        {
            Write-Verbose "Group not found, looking for user"
            $userOrGroup = Get-AzDoUsers -AzDoConnection $AzDoConnection | ? { $_.displayName -eq $UserOrGroupName -or $_.principalName -eq $UserOrGroupName}
        }

        if ($userOrGroup -eq $null)
        {
            Write-Error -ErrorAction $errorPreference -Message "User/Group not found"
        }

        # PUT https://<acct>.visualstudio.com/_apis/securityroles/scopes/distributedtask.variablegroup/roleassignments/resources/<projID>$<VarGroupID>?api-version=5.0-preview.1
        # [{"roleName":"<role>","userId":",<UserGUID>"}]
        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.OrganizationUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/securityroles/scopes/distributedtask.variablegroup/roleassignments/resources/$($AzDoConnection.ProjectId)`$$($variableGroup.Id)"

        $body = "[{`"roleName`":`"$($RoleName)`",`"userId`":`"$($userOrGroup.originId)`"}]"
        # $roleDetails = @()
        # $roleDetails += @{roleName=$RoleName;userId=$($userOrGroup.originId)}
        # $body = $roleDetails | ConvertTo-Json -Depth 10 -Compress

        Write-Verbose "---------BODY---------"
        Write-Verbose $body
        Write-Verbose "---------BODY---------"

        # {"count":1,"value":[{"identity":{"displayName":"[3Pager]\\Variable Groups Managers - AWS","id":"e208eaf7-5b55-40a9-8898-0d43ade92799","uniqueName":"[3Pager]\\Variable Groups Managers - AWS"},"role":{"displayName":"User","name":"User","allowPermissions":17,"denyPermissions":0,"identifier":"distributedtask.variablegroup.User","description":"User can use, but cannot manage the library items.","scope":"distributedtask.variablegroup"},"access":"assigned","accessDisplayName":"Assigned"}]}
        $respomse = Invoke-RestMethod $apiUrl -Method PUT -Body $body -ContentType 'application/json' -Header $($AzDoConnection.HttpHeaders)
        
        Write-Verbose "Response: $($response.id)"

        $response
    }
    END 
    { 
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}
