<#

.SYNOPSIS
This command provides the ability to add a new member to an existing Azure DevOps security group

.DESCRIPTION
The command will add the speciifed user/group to the security group as a member

.PARAMETER AzDoConnect
A valid AzDoConnection object

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.PARAMETER Name
The name of the group 

.PARAMETER MemberName
The name of the user or group to add

.EXAMPLE
Add-AzDoSecurityGroupMember -GroupName <group name> -MemberName <member to add to group>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Add-AzDoSecurityGroupMember()
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
        [parameter(Mandatory=$false, ValueFromPipelinebyPropertyName=$true)][string]$GroupName,
        [parameter(Mandatory=$false)][string]$MemberName
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

        $groups = Get-AzDoSecurityGroups -AzDoConnection $AzDoConnection 
        $g = $groups | ? { $_.displayName -like $GroupName -or $_.principalName -like $GroupName} 
        if ($null -eq $g) { Write-Error -ErrorAction $errorPreference -Message "Failed to find requested Group: $($GroupName)" }

        $m = Get-AzDoUserEntitlements -AzDoConnection $AzDoConnection | ? { $_.user.displayName -like $MemberName -or $_.user.principalName -like $MemberName }
        if ($null -eq $m) { $m =  Get-AzDoTeams -AzDoConnection $AzDoConnection | ? { $_.name -like $MemberName } } 
        if ($null -eq $m) { $m =  $groups | ? { $_.displayName -like $MemberName -or $_.principalName -like $MemberName } } 
        if ($null -eq $m) { Write-Error -ErrorAction $errorPreference -Message "Specified Member could not be found: $($MemberName)" }

        #$apiParams += "scopeDescriptor=$($AzDoConnection.ProjectDescriptor)"

        # PUT https://vssps.dev.azure.com/{orgName}/_apis/graph/Memberships/{subjectDescriptor}/{groupDescriptor}?api-version=5.0-preview.1
        $apiUrl = Get-AzDoApiUrl -RootPath $AzDoConnection.VsspUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/graph/Memberships/$($m.descriptor)/$($g.descriptor)" -QueryStringParams $apiParams

        if (-Not $WhatIfPreference)
        {
            $result = Invoke-RestMethod $apiUrl -Method PUT -Body $body -ContentType 'application/json' -Header $($AzDoConnection.HttpHeaders)    
        }
        
        Write-Verbose "---------RESULT---------"
        Write-Verbose ($result | ConvertTo-Json -Depth 50 | Out-String)
        Write-Verbose "---------RESULT---------"

        #$result
    }
    END { 
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}

