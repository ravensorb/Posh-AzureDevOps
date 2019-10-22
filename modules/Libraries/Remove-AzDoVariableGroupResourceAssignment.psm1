<#

.SYNOPSIS
Remove permission for a specific Azure DevOps libary

.DESCRIPTION
The command will remove the permissions for the specificed variable group

.PARAMETER VariableGroupName
The name of the variable group to retrieve

.PARAMETER UserOrGroupName
The name of the user or group to remove

.PARAMETER AzDoConnection
A valid AzDo connection object

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Remove-AzDoVariableGroupResourceAssignment -VariableGroupName <variable group name> -UserOrGroupName <valid group name>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Remove-AzDoVariableGroupResourceAssignment()
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
        [parameter(Mandatory=$false, ValueFromPipelinebyPropertyName=$true, ParameterSetName="Name")][Alias("name")][string]$VariableGroupName,
        [parameter(Mandatory=$false, ValueFromPipelinebyPropertyName=$true, ParameterSetName="ID")][Alias("id")][int]$VariableGroupId,

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
    
        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.2-preview" }
        if (-Not $ApiVersion.Contains("preview")) { $ApiVersion = "5.2-preview" }

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

        $variableGroup = Get-AzDoVariableGroups -AzDoConnection $AzDoConnection | ? { $_.name -like $VariableGroupName -or $_.id -eq $VariableGroupId }

        if ($null -eq $variableGroup)
        {
            Write-Error -ErrorAction $errorPreference -Message "Variable Group '[$($VariableGroupId)]:$($VariableGroupName)' not found"
        }

        $resourceAssignments = Get-AzDoVariableGroupResourceAssignments -VariableGroupName $($variableGroup.name) | ? { ($_.identity.displayName -eq $UserOrGroupName -or $_.identity.principalName -eq $UserOrGroupName) } 

        if ($null -eq $resourceAssignments -or $resourceAssignments.length -eq 0)
        {
            Write-Error -ErrorAction $errorPreference -Message "User/Group '$($UserOrGroupName)' not found"
        }
        #Write-Verbose $resourceAssignments.identity

        $assignmentsToDelete = @()
        $assignmentsToDelete += ""

        $resourceAssignments | % {
            Write-Verbose "Removing User/Group: '$($_.identity.displayName)' from '$($VariableGroupName)'"
            if ($_.access -ne "assigned") 
            {   
                Write-Verbose ($_ | ConvertTo-Json | Out-String )
                Write-Warning "`tUser '$($_.identity.displayName)' access to '$($VariableGroupName)' is '$($_.access)'.  It should be 'Assigned'. This might be an issue."
            }
            
            $assignmentsToDelete += $_.identity.id
        }

        $body = $assignmentsToDelete | ConvertTo-Json -Depth 50 -Compress
        $body = $body.Replace("`"`",","")

        Write-Verbose "---------BODY---------"
        Write-Verbose $body
        Write-Verbose "---------BODY---------"

        # https://dev.azure.com/3pager/_apis/securityroles/scopes/distributedtask.variablegroup/roleassignments/resources/5d4ef62e-538a-42e9-a02e-e25bce16abee%245
        # PUT https://<acct>.visualstudio.com/_apis/securityroles/scopes/distributedtask.variablegroup/roleassignments/resources/<projID>$<VarGroupID>?api-version=5.0-preview.1
        # [{"roleName":"<role>","userId":",<UserGUID>"}]
        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.OrganizationUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/securityroles/scopes/distributedtask.variablegroup/roleassignments/resources/$($AzDoConnection.ProjectId)`$$($variableGroup.Id)"

        if (-Not $WhatIfPreference) 
        {
            $response = Invoke-RestMethod $apiUrl -Method PATCH -Body $body -ContentType 'application/json' -Header $($AzDoConnection.HttpHeaders)  
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
