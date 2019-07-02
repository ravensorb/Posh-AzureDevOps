<#

.SYNOPSIS
This commend provides creates a new Security Groups for Azure DevOps

.DESCRIPTION
The command will create a new Azure DevOps security group

.PARAMETER AzDoConnect
A valid AzDoConnection object

.PARAMETER ProjectUrl
The full url for the Azure DevOps Project.  For example https://<organization>.visualstudio.com/<project> or https://dev.azure.com/<organization>/<project>

.PARAMETER PAT
A valid personal access token with at least read access for build definitions

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.PARAMETER GroupName
The name of the group to create

.EXAMPLE
Create-AzDoSecurityGroup -GroupName <group name>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function New-AzDoSecurityGroup()
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
        [string][parameter(ValueFromPipelinebyPropertyName = $true)]$GroupName,
        [string]$GroupDescription
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
            if ([string]::IsNullOrEmpty($ProjectUrl))
            {
                $AzDoConnection = Get-AzDoActiveConnection

                if ($null -eq $AzDoConnection) { throw "AzDoConnection or ProjectUrl must be valid" }
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

        $apiParams += "scopeDescriptor=$($AzDoConnection.ProjectDescriptor)"

        # POST https://vssps.dev.azure.com/fabrikam/_apis/graph/groups?scopeDescriptor=&api-version=5.0-preview.1
        # {
        #    "displayName": "Developers-0db1aa79-b8e8-4e33-8347-52edb8135430",
        #    "description": "Group created via client library"
        # }
        $apiUrl = Get-AzDoApiUrl -RootPath $AzDoConnection.VsspUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/graph/groups" -QueryStringParams $apiParams
        $body = ConvertFrom-Json "{'name':'$($GroupName)', 'description': '$($GroupDescription)'}"

        $groupDetails = @{displayName=$GroupName;description=$GroupDescription}
        $body = $groupDetails | ConvertTo-Json -Depth 10 -Compress

        Write-Verbose $body

        $group = Invoke-RestMethod $apiUrl -Method POST -Body $body -ContentType 'application/json' -Header $($AzDoConnection.HttpHeaders)    
        
        Write-Verbose "---------GROUP---------"
        Write-Verbose $group
        Write-Verbose "---------GROUP---------"

        $group
    }
    END { }
}

