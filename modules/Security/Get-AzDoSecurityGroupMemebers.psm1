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
        [PoshAzDo.AzDoConnectObject][parameter(ValueFromPipelinebyPropertyName = $true, ValueFromPipeline = $true)]$AzDoConnection,
        [string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [string][parameter(ParameterSetName="Name", ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][Alias("name")]$GroupName,
        [Guid][parameter(ParameterSetName="ID", ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][Alias("id")]$GroupId = [Guid]::Empty
    )
    BEGIN
    {
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }        

        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0-preview.1" }
        if (-Not $ApiVersion.Contains("preview")) { $ApiVersion = "5.0-preview.1" }

        if (-Not (Test-Path varaible:$AzDoConnection) -and $null -eq $AzDoConnection)
        {
            $AzDoConnection = Get-AzDoActiveConnection

            if ($null -eq $AzDoConnection) { throw "AzDoConnection or ProjectUrl must be valid" }
        }

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "`tParameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "`t`t$_ = '$($PSBoundParameters[$_])'" }        
    }
    PROCESS
    {
        if ($GroupId -ne [Guid]::Empty) {
            $group = Get-AzDoSecurityGroups -AzDoConnection $AzDoConnection -GroupId $GroupId
        } else {
            $group = Get-AzDoSecurityGroups -AzDoConnection $AzDoConnection -GroupName $GroupName
        }

        if ($null -eq $group) { throw "Specified group not found" }

        $apiParams = @()

        $apiParams += "direction=Down"

        # GET https://vssps.dev.azure.com/fabrikam/_apis/graph/Memberships/{subjectDescriptor}?direction=Down&api-version=5.0-preview.1
        $apiUrl = Get-AzDoApiUrl -RootPath $AzDoConnection.VsspUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/graph/Memberships/$($group.descriptor)" -QueryStringParams $apiParams

        $groupMembers = Invoke-RestMethod $apiUrl -Headers $AzDoConnection.HttpHeaders
        
        Write-Verbose "---------GROUP MEMBERS---------"
        Write-Verbose $groupMembers
        Write-Verbose "---------GROUP MEMBERS---------"

        if ($groupMembers.count -ne $null)
        {   
            foreach ($member in $groupMembers.value)
            {
                Write-Verbose "Group Member: $($member.memberDescriptor)"

                Get-AzDoUserDetails -UserDescriptor $($member.memberDescriptor)
            }
        } 

        Write-Verbose "No group members found."
        
        return $null
    }
    END { }
}

