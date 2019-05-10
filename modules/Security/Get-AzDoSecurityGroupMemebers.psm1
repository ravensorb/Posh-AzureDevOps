<#

.SYNOPSIS
This commend provides retrieve Security Group Members from Azure DevOps

.DESCRIPTION
The command will retrieve Azure DevOps security group members (if they exists) 

.PARAMETER AzDoConnect
A valid AzDoConnection object

.PARAMETER ProjectUrl
The full url for the Azure DevOps Project.  For example https://<organization>.visualstudio.com/<project> or https://dev.azure.com/<organization>/<project>

.PARAMETER PAT
A valid personal access token with at least read access for build definitions

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.PARAMETER TeamName
The name of the build definition to retrieve (use on this OR the id parameter)

.EXAMPLE
Get-AzDoSecurityGroupMembers -ProjectUrl https://dev.azure.com/<organizztion>/<project> -GroupName <group name>

.EXAMPLE
Get-AzDoSecurityGroupMembers -ProjectUrl https://dev.azure.com/<organizztion>/<project> -GroupId <group id>

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
        [string][parameter(ValueFromPipelinebyPropertyName = $true)]$ProjectUrl,
        [string][parameter(ValueFromPipelinebyPropertyName = $true)]$PAT,
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

        if (-Not (Test-Path varaible:$AzDoConnection) -and $AzDoConnection -eq $null)
        {
            if ([string]::IsNullOrEmpty($ProjectUrl))
            {
                $AzDoConnection = Get-AzDoActiveConnection

                if ($AzDoConnection -eq $null) { throw "AzDoConnection or ProjectUrl must be valid" }
            }
            else 
            {
                $AzDoConnection = Connect-AzDo -ProjectUrl $ProjectUrl -PAT $PAT -LocalOnly
            }
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

        if ($group -eq $null) { throw "Specified group not found" }

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

