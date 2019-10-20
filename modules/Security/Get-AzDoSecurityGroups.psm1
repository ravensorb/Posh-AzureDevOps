<#

.SYNOPSIS
This command provides retrieve Security Groups from Azure DevOps

.DESCRIPTION
The command will retrieve Azure DevOps security groups (if they exists) 

.PARAMETER AzDoConnect
A valid AzDoConnection object

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Get-AzDoSecurityGroups 

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
        [parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelinebyPropertyName=$true)][PoshAzDo.AzDoConnectObject]$AzDoConnection,
        [parameter(Mandatory=$false)][string]$ApiVersion = $global:AzDoApiVersion

        # Module Parameters
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

        $apiParams += "subjectTypes=vssgp"
        $apiParams += "scopeDescriptor=$($AzDoConnection.ProjectDescriptor)"

        # GET https://vssps.dev.azure.com/{organization}/_apis/graph/groups?scopeDescriptor={scopeDescriptor}&subjectTypes={subjectTypes}&continuationToken={continuationToken}&api-version=5.0-preview.1
        $apiUrl = Get-AzDoApiUrl -RootPath $AzDoConnection.VsspUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/graph/groups" -QueryStringParams $apiParams

        $groups = Invoke-RestMethod $apiUrl -Headers $AzDoConnection.HttpHeaders
        
        Write-Verbose "---------GROUPS---------"
        Write-Verbose ($groups| ConvertTo-Json -Depth 50 | Out-String)
        Write-Verbose "---------GROUPS---------"

        if ($null -ne $groups.count -and $groups.count -gt 0)
        {   
            #TODO Need to find a better way to do this!
            # This is a HACK to filter out all Teams from the list of groups.
            $teams = Get-AzDoTeams -AzDoConnection $AzDoConnection

            foreach($item in $groups.value)
            {
                [bool]$found = $false
                foreach ($team in $teams)
                {
                    if ($item.displayName -eq $team.name) { $found = $true }
                }

                if (-Not $found) { $item }
            }
        } 
        else 
        {
            Write-Verbose "No groups found."
            
            return $null
        }
    }
    END 
    { 
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}

