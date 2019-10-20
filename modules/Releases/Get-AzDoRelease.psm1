<#

.SYNOPSIS
Retrieve the release for the specified release defintion 

.DESCRIPTION
The command will retrieve a full release details for the specified definition (if it exists) 

.PARAMETER ReleaseDefinitionName
The name of the release definition to retrieve (use on this OR the id parameter)

.PARAMETER ReleaseDefinitionId
The id of the release definition to retrieve (use on this OR the name parameter)

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Get-AzDoReleases -ProjectUrl https://dev.azure.com/<organizztion>/<project> -ReleaseDefinitionName <release defintiion name> -PAT <personal access token>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Get-AzDoReleases()
{
    [CmdletBinding(
        DefaultParameterSetName='Name'
    )]
    param
    (
        # Common Parameters
        [parameter(Mandatory=$false, ValueFromPipelinebyPropertyName=$true, ValueFromPipeline=$true)][PoshAzDo.AzDoConnectObject]$AzDoConnection,
        [parameter(Mandatory=$false)][string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [parameter(Mandatory=$false, ParameterSetName="Name", ValueFromPipelinebyPropertyName=$true)][string]$ReleaseDefinitionName,
        [parameter(Mandatory=$false, ParameterSetName="ID", ValueFromPipelinebyPropertyName=$true)][int]$ReleaseDefinitionId,
        [parameter(Mandatory=$false)][int]$Count = 1
    )
    BEGIN
    {
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }        
    
        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0"}

        if (-Not (Test-Path varaible:$AzDoConnection) -or $null -eq $AzDoConnection)
        {
            $AzDoConnection = Get-AzDoActiveConnection

            if ($null -eq $AzDoConnection) { throw "AzDoConnection or ProjectUrl must be valid" }
        }

        if ($ReleaseDefinitionId -eq $null -and [string]::IsNullOrEmpty($ReleaseDefinitionName)) { throw "Definition ID or Name must be specified"; }

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "`tParameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "`t`t$_ = '$($PSBoundParameters[$_])'" }             
    }
    PROCESS
    {
        $releaseDefinition = $null

        if ($ReleaseDefinitionId -ne $null -and $ReleaseDefinitionId -ne 0) 
        {
            $releaseDefinition = Get-AzDoReleaseDefinition -AzDoConnection $AzDoConnection -ApiVersion $ApiVersion -ReleaseDefinitionId $ReleaseDefinitionId 
        }
        elseif (-Not [string]::IsNullOrEmpty($ReleaseDefinitionName))
        {
            $releaseDefinition = Get-AzDoReleaseDefinition -AzDoConnection $AzDoConnection -ApiVersion $ApiVersion -ReleaseDefinitionName $ReleaseDefinitionName 
        }

        if (-Not $releaseDefinition)
        {
            throw "Release defintion specified was not found"
        }
        
        $apiParams = @()

        $apiParams += "`$top=$($Count)"
        $apiParams += "definitions=$($definition.Id)"
        $apiParams += "expand=EnvironmentStatus"

        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.ReleaseManagementUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/release/releases" -QueryStringParams $apiParams

        $releases = Invoke-RestMethod $apiUrl -Headers $AzDoConnection.HttpHeaders

        Write-Verbose "---------RELEASES---------"
        Write-Verbose $releases
        Write-Verbose "---------RELEASES---------"

        #Write-Verbose "Release $($build.id) not found."
        
        $releases.value
    }
    END { }
}

