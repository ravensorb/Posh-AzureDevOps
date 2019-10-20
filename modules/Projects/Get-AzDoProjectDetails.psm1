<#

.SYNOPSIS
This command provides retrieve Project Details from Azure DevOps

.DESCRIPTION
The command will retrieve Azure DevOps project details (if they exists) 

.PARAMETER AzDoConnect
A valid AzDoConnection object

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.PARAMETER TeamName
The name of the build definition to retrieve (use on this OR the id parameter)

.EXAMPLE
Get-AzDoProjectDetails -ProjectName <project name>

.EXAMPLE
Get-AzDoProjectDetails -ProjectId <project id>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Get-AzDoProjectDetails()
{
    [CmdletBinding(
        DefaultParameterSetName="ID"
    )]
    param
    (
        # Common Parameters
        [parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelinebyPropertyName=$true)][PoshAzDo.AzDoConnectObject]$AzDoConnection,
        [parameter(Mandatory=$false)][string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [parameter(Mandatory=$true, ParameterSetName="Name")][Alias("name")][string]$ProjectName,
        [parameter(Mandatory=$true, ParameterSetName="ID", ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][Alias("id")][Guid]$ProjectId
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

        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0"}

        if (-Not (Test-Path varaible:$AzDoConnection) -and $AzDoConnection -eq $null)
        {
            $AzDoConnection = Get-AzDoActiveConnection

            if ($null -eq $AzDoConnection) { Write-Error -ErrorAction $errorPreference -Message "AzDoConnection or ProjectUrl must be valid" }
        }

        if ([string]::IsNullOrEmpty($ProjectName) -and $ProjectId -eq $null) { Write-Error -ErrorAction $errorPreference -Message "Project Name or ID required" }

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "`tParameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "`t`t$_ = '$($PSBoundParameters[$_])'" }        
    }
    PROCESS
    {
        $apiParams = @()

        # https://dev.azure.com/{organization}/_apis/projects/{projectId}?api-version=5.0
        if (-Not [string]::IsNullOrEmpty($ProjectName))
        {
            $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.OrganizationUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/projects/$($ProjectName)" 
        } else {
            $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.OrganizationUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/projects/$($ProjectId)" 
        }
        $projectDetails = Invoke-RestMethod $apiUrl -Headers $AzDoConnection.HttpHeaders

        Write-Verbose "---------PROJECTS DETAILS---------"
        Write-Verbose ($projectDetails| ConvertTo-Json -Depth 50 | Out-String)
        Write-Verbose "---------PROJECTS DETAILS---------"

        return $projectDetails
    }
    END 
    { 
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}

