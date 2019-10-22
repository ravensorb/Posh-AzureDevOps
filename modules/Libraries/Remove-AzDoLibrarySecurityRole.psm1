<#

.SYNOPSIS
Remove permission for a specific Azure DevOps libary

.DESCRIPTION
The command will remove the permissions for the specificed variable group

.PARAMETER UserOrGroupName
The name of the user, group, or team name

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
REmove-AzDoLibrarySecurityRole -UserOrGroupName <user or group/team name> 

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Remove-AzDoLibrarySecurityRole()
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
        [parameter(Mandatory=$false, ValueFromPipelinebyPropertyName=$true)][string]$UserOrGroupName
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
    
        if ((-Not (Test-Path variable:ApiVersion)) -or $ApiVersion -ne "6.0-preview") { $ApiVersion = "6.0-preview" }
        if (-Not $ApiVersion.Contains("preview")) { $ApiVersion = "6.0-preview" }

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
        $userOrGroup = Get-AzDoIdentities -AzDoConnection $AzDoConnection -QueryString "[$($AzDoConnection.ProjectName)]\$UserOrGroupName"

        if ($null -eq $userOrGroup)
        {
            Write-Error -ErrorAction $errorPreference -Message "User/Group/Team not found"
            return
        }

        # PUT https://<acct>.visualstudio.com/_apis/securityroles/scopes/distributedtask.library/roleassignments/resources/<projID>?api-version=5.0-preview.1
        # [{"roleName":"<role>","userId":",<UserGUID>"}]
        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.OrganizationUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/securityroles/scopes/distributedtask.library/roleassignments/resources/$($AzDoConnection.ProjectId)`$0"

        $body = "[`"$($userOrGroup.originId)`"]"
        # $roleDetails = @()
        # $roleDetails += @{roleName=$RoleName;userId=$($userOrGroup.originId)}
        # $body = $roleDetails | ConvertTo-Json -Depth 50 -Compress

        Write-Verbose "---------BODY---------"
        Write-Verbose $body
        Write-Verbose "---------BODY---------"

        if (-Not $WhatIfPreference) 
        {
            $response = Invoke-RestMethod $apiUrl -Method PATCH -Body $body -ContentType 'application/json' -Header $($AzDoConnection.HttpHeaders)
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
