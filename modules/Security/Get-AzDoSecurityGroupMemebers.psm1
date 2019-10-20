<#

.SYNOPSIS
This command provides retrieve Security Group Members from Azure DevOps

.DESCRIPTION
The command will retrieve Azure DevOps security group members (if they exists) 

.PARAMETER AzDoConnect
A valid AzDoConnection object

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.PARAMETER TeamName
The name of the build definition to retrieve (use on this OR the id parameter)

.EXAMPLE
Get-AzDoSecurityGroupMembers -GroupName <group name>

.EXAMPLE
Get-AzDoSecurityGroupMembers -GroupId <group id>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Get-AzDoSecurityGroupMembers()
{
    [CmdletBinding(
        DefaultParameterSetName="Id"
    )]
    param
    (
        # Common Parameters
        [parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelinebyPropertyName=$true)][PoshAzDo.AzDoConnectObject]$AzDoConnection,
        [parameter(Mandatory=$false)][string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [parameter(Mandatory=$false, ParameterSetName="Name", ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][Alias("name")][string]$GroupName
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
        $groups = Get-AzDoSecurityGroups -AzDoConnection $AzDoConnection
        $group = $groups | ? { $_.displayName -like $GroupName -or $_.principalName -like $GroupName} 

        if ($null -eq $group) { Write-Error -ErrorAction $errorPreference -Message "Specified group not found" }

        Write-Verbose "Found Group: $($group.descriptor):'$($group.displayName)'"

        $apiParams = @()

        $apiParams += "direction=Down"

        # GET https://vssps.dev.azure.com/fabrikam/_apis/graph/Memberships/{subjectDescriptor}?direction=Down&api-version=5.0-preview.1
        $apiUrl = Get-AzDoApiUrl -RootPath $AzDoConnection.VsspUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/graph/Memberships/$($group.descriptor)" -QueryStringParams $apiParams

        $groupMembers = Invoke-RestMethod $apiUrl -Headers $AzDoConnection.HttpHeaders
        
        Write-Verbose "---------GROUP MEMBERS---------"
        Write-Verbose ($groupMembers| ConvertTo-Json -Depth 50 | Out-String)
        Write-Verbose "---------GROUP MEMBERS---------"

        $groupMembers.value | % {
            $member = $_

            Write-Verbose "Group Member: $($member.memberDescriptor)"

            if ($member.memberDescriptor -like "vssgp.*")
            {
                $g = $groups | ? { $_.descriptor -eq $member.memberDescriptor }

                Write-Verbose "`tGroup: $($g.displayName)"

                $g
            }
            elseif ($member.memberDescriptor -like "aad.*")
            {
                $u = Get-AzDoUserDetails -AzDoConnection $AzDoConnection -UserDescriptor $($member.memberDescriptor)

                Write-Verbose "`tUser: $($u.displayName)"

                $u
            } else {
                Write-Verbose "Unknown Membership Descriptor: $($member.memberDescriptor)"
            }
        }
    }
    END 
    { 
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}

