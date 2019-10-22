<#

.SYNOPSIS
This command provides creates a new Security Groups for Azure DevOps

.DESCRIPTION
The command will create a new Azure DevOps security group

.PARAMETER AzDoConnect
A valid AzDoConnection object

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.PARAMETER GroupName
The name of the group to create

.PARAMETER GroupDescription
The description  of the group to create

.EXAMPLE
Create-AzDoSecurityGroup -GroupName <group name>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function New-AzDoSecurityGroup()
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
        [parameter(Mandatory=$false)][string]$GroupDescription
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

        $apiParams += "scopeDescriptor=$($AzDoConnection.ProjectDescriptor)"

        # POST https://vssps.dev.azure.com/fabrikam/_apis/graph/groups?scopeDescriptor=&api-version=5.0-preview.1
        # {
        #    "displayName": "Developers-0db1aa79-b8e8-4e33-8347-52edb8135430",
        #    "description": "Group created via client library"
        # }
        $apiUrl = Get-AzDoApiUrl -RootPath $AzDoConnection.VsspUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/graph/groups" -QueryStringParams $apiParams
        $body = ConvertFrom-Json "{'name':'$($GroupName)', 'description': '$($GroupDescription)'}"

        $groupDetails = @{displayName=$GroupName;description=$GroupDescription}
        $body = $groupDetails | ConvertTo-Json -Depth 50 -Compress

        Write-Verbose "---------BODY---------"
        Write-Verbose $body
        Write-Verbose "---------BODY---------"

        if (-Not $WhatIfPreference)
        {
            $group = Invoke-RestMethod $apiUrl -Method POST -Body $body -ContentType 'application/json' -Header $($AzDoConnection.HttpHeaders)    
        }
        
        Write-Verbose "---------GROUP---------"
        Write-Verbose ($group| ConvertTo-Json -Depth 50 | Out-String)
        Write-Verbose "---------GROUP---------"

        $group
    }
    END 
    { 
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}

