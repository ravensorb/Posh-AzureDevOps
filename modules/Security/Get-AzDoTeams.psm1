<#

.SYNOPSIS
This command provides retrieve Teams from Azure DevOps

.DESCRIPTION
The command will retrieve Azure DevOps teams (if they exists) 

.PARAMETER AzDoConnect
A valid AzDoConnection object

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.PARAMETER Mine
Indicates that only your teams should be returned

.EXAMPLE
Get-AzDoTeams -ProjectUrl https://dev.azure.com/<organizztion>/<project>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Get-AzDoTeams()
{
    [CmdletBinding(
    )]
    param
    (
        # Common Parameters
        [parameter(Mandatory=$false, ValueFromPipelinebyPropertyName=$true)][PoshAzDo.AzDoConnectObject]$AzDoConnection,
        [parameter(Mandatory=$false)][string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [parameter(Mandatory=$false)][switch]$Mine
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

        if (-Not $ApiVersion.Contains("preview")) { $ApiVersion = "5.0-preview.2" }
        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0-preview.2"}


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

        if ($Mine) 
        {
            $apiParams += "Mine=true"
        }

        # https://dev.azure.com/{organization}/_apis/projects/{projectId}/teams?api-version=5.0
        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.OrganizationUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/projects/$($AzDoConnection.ProjectName)/teams" -QueryStringParams $apiParams

        $teamsResult = Invoke-RestMethod $apiUrl -Headers $AzDoConnection.HttpHeaders
        
        Write-Verbose "---------TEAMS---------"
        Write-Verbose ($teamsResult| ConvertTo-Json -Depth 50 | Out-String)
        Write-Verbose "---------TEAMS---------"

        $teamsResult.value | ForEach-Object { 
            #id          : [Guid]
            #name        : [string]
            #url         : [string]
            #description : [string]
            #identityUrl : [string]
            #projectName : [string]
            #projectId   : [Guid]
           
            Write-Verbose "`t$($_.id) => $($_.name)"

            # Convert to a strongly typed object
            $team = [pscustomobject]@{
                id = [Guid]$_.id;
                name = [string]$_.name;
                url = [string]$_.url;
                description = [string]$_.description;
                identityUrl = [string]$_.identityUrl;
                projectName = [string]$_.projectName;
                projectId = [Guid]$_.projectId;
            }

            $team
        }        
    }
    END { 
    }
}

