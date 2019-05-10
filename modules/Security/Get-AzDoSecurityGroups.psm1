<#

.SYNOPSIS
This commend provides retrieve Security Groups from Azure DevOps

.DESCRIPTION
The command will retrieve Azure DevOps security groups (if they exists) 

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
Get-AzDoSecurityGroups -ProjectUrl https://dev.azure.com/<organizztion>/<project>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Get-AzDoSecurityGroups()
{
    [CmdletBinding(
        DefaultParameterSetName="Name"
    )]
    param
    (
        # Common Parameters
        [PoshAzDo.AzDoConnectObject][parameter(ValueFromPipelinebyPropertyName = $true, ValueFromPipeline = $true)]$AzDoConnection,
        [string][parameter(ValueFromPipelinebyPropertyName = $true)]$ProjectUrl,
        [string][parameter(ValueFromPipelinebyPropertyName = $true)]$PAT,
        [string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [string][parameter(ParameterSetName="Name")]$GroupName,
        [Guid][parameter(ParameterSetName="Id")]$GroupId = [Guid]::Empty
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
        $apiParams = @()

        $apiParams += "subjectTypes=vssgp"
        $apiParams += "scopeDescriptor=$($AzDoConnection.ProjectDescriptor)"

        # GET https://vssps.dev.azure.com/{organization}/_apis/graph/groups?scopeDescriptor={scopeDescriptor}&subjectTypes={subjectTypes}&continuationToken={continuationToken}&api-version=5.0-preview.1
        $apiUrl = Get-AzDoApiUrl -RootPath $AzDoConnection.VsspUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/graph/groups" -QueryStringParams $apiParams

        $groups = Invoke-RestMethod $apiUrl -Headers $AzDoConnection.HttpHeaders
        
        Write-Verbose "---------GROUPS---------"
        Write-Verbose $groups
        Write-Verbose "---------GROUPS---------"

        if ($groups.count -ne $null -and $groups.count -gt 0)
        {   
            Write-Verbose "Found $($groups.count) groups"
            if (-Not [string]::IsNullOrEmpty($GroupName) -or $GroupId -ne [Guid]::Empty)
            {
                Write-Verbose "Looking for a specific group $GroupId - $GroupName"

                foreach($item in $groups.value)
                {
                    Write-Verbose "Group: $($item.originId) - $($item.displayName)"

                    if ($item.displayName -like "*$($GroupName)*" -or $item.originId -eq $GroupId) {
                        Write-Verbose "Group Found '$($item.displayName)' found."

                        return $item;
                    }                     
                }
            }
            else {
                return $groups.value
            }
        } 

        Write-Verbose "No groups found."
        
        return $null
    }
    END { }
}

