<#

.SYNOPSIS
This command provides the ability to add a new member to an Azure DevOps Sevice Endpoint

.DESCRIPTION
The command will add the speciifed user/group for a speciifc role to the service endpoint

.PARAMETER AzDoConnect
A valid AzDoConnection object

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.PARAMETER EndpointName
The name of the service endpoint

.PARAMETER MemberName
The name of the user or group to add

.PARAMETER RoleName
The name of the role to add the member to

.EXAMPLE
Add-AzDoServiceEndpointSecurityRole -EndpointName <end point name> -UserName <user name> -RoleName <role name>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Add-AzDoServiceEndpointSecurityRole()
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
        [parameter(Mandatory=$false, ValueFromPipelinebyPropertyName=$true, ParameterSetName="Name")][string]$EndpointName,
        [parameter(Mandatory=$false, ValueFromPipelinebyPropertyName=$true, ParameterSetName="ID")][Guid]$EndpointId,

        [parameter(Mandatory=$false)][string]$MemberName,
        [parameter(Mandatory=$false)][string]$RoleName
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
        Write-Verbose "`tParameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "`t`t$_ = '$($PSBoundParameters[$_])'" }        
    }
    PROCESS
    {
        $apiParams = @()

        $serviceEndpoint = Get-AzDoServiceEndpoints -AzDoConnection $AzDoConnection | ? { $_.id -eq $EndpointId -or $_.name -like $EndpointName} 
        $serviceEndpoint = @{}
        $serviceEndpoint.id = [Guid]::Parse("3f987c30-261f-4e27-878a-3d929faf109d")

        if ($null -eq $serviceEndpoint)
        {
            Write-Error -Message "Failed to find specified service endpoint"

            return
        }

        $m = Get-AzDoUserEntitlements -AzDoConnection $AzDoConnection | ? { $_.user.displayName -like $MemberName -or $_.user.principalName -like $MemberName -or $_.user.mailAddress -like $MemberName }
        if ($null -eq $m) { $m =  Get-AzDoTeams -AzDoConnection $AzDoConnection | ? { $_.name -like $MemberName } } 
        if ($null -eq $m) { $m =  Get-AzDoSecurityGroups -AzDoConnection $AzDoConnection | ? { $_.displayName -like $MemberName -or $_.principalName -like $MemberName } } 
        if ($null -eq $m) { Write-Error -ErrorAction $errorPreference -Message "Specified Member could not be found: $($MemberName)" }

        if ($null -eq $m)
        {
            Write-Error -Message "Unable to locate specifed member: $($MemberName)."
            return
        }

        $role = Get-AzDoServiceEndpointRoles -AzDoConnection $AzDoConnection | ? { $_.displayName -eq $RoleName -or $_.name -eq $RoleName }

        if ($null -eq $role)
        {
            Write-Error -Message "Unable to locate specifed role."
            return
        }

        Write-Verbose "Service Endpoint: $($serviceEndpoint)"
        Write-Verbose "Member: $($m)"
        Write-Verbose "Role: $($role)"

        #3f987c30-261f-4e27-878a-3d929faf109d
        # PUT https://dev.azure.com/{orgName}/_apis/securityroles/scopes/distributedtask.serviceendpointrole/roleassignments/resources/{resourceEndpointId}?api-version=5.0-preview.1
        $apiUrl = Get-AzDoApiUrl -RootPath $AzDoConnection.OrganizationUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/securityroles/scopes/distributedtask.serviceendpointrole/roleassignments/resources/$($serviceEndpoint.id)" -QueryStringParams $apiParams

        $body = "[{'roleName': '$($role.name)', 'userId': '$($m.id)'}]"

        Write-Verbose "---------BODY---------"
        Write-Verbose $body
        Write-Verbose "---------BODY---------"
        #Write-Host $apiUrl

        if (-Not $WhatIfPreference)
        {
            $result = Invoke-RestMethod $apiUrl -Method PUT -Body $body -ContentType 'application/json' -Header $($AzDoConnection.HttpHeaders)    
        }
        
        if ($null -ne $result)
        {
            Write-Verbose "---------RESULT---------"
            Write-Verbose ($result| ConvertTo-Json -Depth 50 | Out-String)
            Write-Verbose "---------RESULT---------"

            $result.value
        }
        else 
        {
            Write-Verbose "No results found"
        }
    }
    END 
    { 
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}

