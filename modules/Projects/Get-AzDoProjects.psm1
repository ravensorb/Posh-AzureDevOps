<#

.SYNOPSIS
This command provides suppot to retrieve Projects from Azure DevOps

.DESCRIPTION
The command will retrieve Azure DevOps projects (if they exists) 

.PARAMETER AzDoConnect
A valid AzDoConnection object

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.PARAMETER ProjectName
The name of the project to retrieve

.EXAMPLE
Get-AzDoprojects

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Get-AzDoProjects()
{
    [CmdletBinding(
    )]
    param
    (
        # Common Parameters
        [PoshAzDo.AzDoConnectObject][parameter(ValueFromPipelinebyPropertyName = $true, ValueFromPipeline = $true)]$AzDoConnection,
        [string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [string]$ProjectName
    )
    BEGIN
    {
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }        

        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0"}

        if (-Not (Test-Path varaible:$AzDoConnection) -and $AzDoConnection -eq $null)
        {
            $AzDoConnection = Get-AzDoActiveConnection

            if ($AzDoConnection -eq $null) { throw "AzDoConnection or ProjectUrl must be valid" }
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

        # GET https://dev.azure.com/{organization}/_apis/projects?api-version=5.0
        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.OrganizationUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/projects" -QueryStringParams $apiParams

        $projects = Invoke-RestMethod $apiUrl -Headers $AzDoConnection.HttpHeaders
        
        Write-Verbose "---------PROJECTS---------"
        Write-Verbose $projects
        Write-Verbose "---------PROJECTS---------"

        if ($projects.count -ne $null)
        {   
            if (-Not [string]::IsNullOrEmpty($ProjectName))
            {
                foreach($bd in $projects.value)
                {
                    if ($bd.name -like $ProjectName) {
                        $projectDetails = Get-AzDoProjectDetails -AzDoConnection $AzDoConnection -ProjectId $bd.id

                        return $projectDetails
                    }                     
                }
            }
            else {
                return $projects.value
            }
        }
        elseif ($projects -ne $null) {
            return $projects
        }

        Write-Verbose "Project $ProjectName not found."
        
        return $null
    }
    END { }
}

