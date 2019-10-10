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
        DefaultParameterSetName="Name"
    )]
    param
    (
        # Common Parameters
        [PoshAzDo.AzDoConnectObject][parameter(ValueFromPipelinebyPropertyName = $true, ValueFromPipeline = $true)]$AzDoConnection,
        [string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [string][parameter(ValueFromPipelinebyPropertyName = $true, ParameterSetName="Name")]$EndpointName,
        [Guid][parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName="ID")]$EndpointId,

        [string][parameter()]$MemberName,
        [string][parameter()]$RoleName
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

        $serviceEndpoint = Get-AzDoServiceEndpoints -AzDoConnection $AzDoConnection | ? { $_.id -eq $EndpointId -or $_.name -clike $EndpointName} 
        $serviceEndpoint = @{}
        $serviceEndpoint.id = [Guid]::Parse("3f987c30-261f-4e27-878a-3d929faf109d")

        if ($null -eq $serviceEndpoint)
        {
            Write-Error -Message "Failed to find specified service endpoint"

            return
        }

        $member = Get-AzDoUsers -AzDoConnection $AzDoConnection | ? { $_.displayName -clike $MemberName -or $_.principalName -clike $MemberName -or $_.mailaddress -clike $MemberName }
        if ($null -eq $member) 
        {
            $member = Get-AzDoTeams -AzDoConnection $AzDoConnection | ? { $_.displayName -clike $MemberName }
            if ($null -eq $member)
            {
                $member = Get-AzDoSecurityGroups -AzDoConnection $AzDoConnection | ? { $_.displayName -clike $MemberName }
            }
        }

        if ($null -eq $member)
        {
            Write-Error -Message "Unable to locate specifed member."
            return
        }

        $role = Get-AzDoServiceEndpointRoles -AzDoConnection $AzDoConnection | ? { $_.displayName -eq $RoleName -or $_.name -eq $RoleName }

        if ($null -eq $role)
        {
            Write-Error -Message "Unable to locate specifed role."
            return
        }

        Write-Verbose "Service Endpoint: $($serviceEndpoint)"
        Write-Verbose "Member: $($member)"
        Write-Verbose "Role: $($role)"

        #3f987c30-261f-4e27-878a-3d929faf109d
        # PUT https://dev.azure.com/{orgName}/_apis/securityroles/scopes/distributedtask.serviceendpointrole/roleassignments/resources/{resourceEndpointId}?api-version=5.0-preview.1
        $apiUrl = Get-AzDoApiUrl -RootPath $AzDoConnection.OrganizationUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/securityroles/scopes/distributedtask.serviceendpointrole/roleassignments/resources/$($serviceEndpoint.id)" -QueryStringParams $apiParams

        $body = "[{'roleName': '$($role.name)', 'userId': '$($member.originid)'}]"

        Write-Host $apiUrl
        Write-Host $body
        $result = Invoke-RestMethod $apiUrl -Method PUT -ContentType 'application/json' -Header $($AzDoConnection.HttpHeaders)    
        
        if ($null -ne $result)
        {
            Write-Verbose "---------RESULT---------"
            Write-Verbose $result 
            Write-Verbose "---------RESULT---------"

            #$result
        }
        else 
        {
            Write-Verbose "No results found"
        }
    }
    END { }
}

