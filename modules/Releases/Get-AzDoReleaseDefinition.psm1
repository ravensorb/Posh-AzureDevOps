<#

.SYNOPSIS
This commend provides accesss Release Defintiions from Azure DevOps

.DESCRIPTION
The command will retrieve a full release definition (if it exists) 

.PARAMETER ReleaseDefinitionName
The name of the release definition to retrieve (use on this OR the id parameter)

.PARAMETER ReleaseDefinitionId
The id of the release definition to retrieve (use on this OR the name parameter)

.PARAMETER ExpandFields
A common seperated list of fields to expand

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Get-AzDoReleaseDefinition -ProjectUrl https://dev.azure.com/<organizztion>/<project> -ReleaseDefinitionName <release defintiion name> -PAT <personal access token>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Get-AzDoReleaseDefinition()
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
        [parameter(Mandatory=$false)][string]$ExpandFields
    )
    BEGIN
    {
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }        

        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0"}

        if (-Not (Test-Path varaible:$AzDoConnection) -or $AzDoConnection -eq $null)
        {
            $AzDoConnection = Get-AzDoActiveConnection

            if ($AzDoConnection -eq $null) { throw "AzDoConnection or ProjectUrl must be valid" }
        }

        if ($ReleaseDefinitionId -eq $null -and [string]::IsNullOrEmpty($ReleaseDefinitionName)) { throw "Definition ID or Name must be specified";}

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "Parameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "$_ = '$($PSBoundParameters[$_])'" }                 
    }
    PROCESS
    {
        $apiParams = @()

        if (-Not [string]::IsNullOrEmpty($ExpandFields)) 
        {
            $apiParams += "Expand=$($ExpandFields)"
        }

        if ($ReleaseDefinitionId -ne $null -and $ReleaseDefinitionId -ne 0) 
        {
            $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.ReleaseManagementUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/release/definitions/$($ReleaseDefinitionId)" -QueryStringParams $apiParams
        }
        else 
        {
            $apiParams += "searchText=$($ReleaseDefinitionName)"

            $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.ReleaseManagementUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/release/definitions" -QueryStringParams $apiParams
        }

        $releaseDefinitions = Invoke-RestMethod $apiUrl -Headers $AzDoConnection.HttpHeaders 

        Write-Verbose "---------RELEASE DEFINITION BEGIN---------"
        Write-Verbose $releaseDefinitions
        Write-Verbose "---------RELEASE DEFINITION END---------"

        if ($releaseDefinitions.count -ne $null)
        {
            foreach($rd in $releaseDefinitions.value)
            {
                if ($rd.name -like $ReleaseDefinitionName) {
                    Write-Verbose "Release Defintion Found $($rd.name) found."

                    $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.ReleaseManagementUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/release/definitions/$($rd.id)" -QueryStringParams $apiParams
                    $releaseDefinitions = Invoke-RestMethod $apiUrl -Headers $AzDoConnection.HttpHeaders 

                    return $releaseDefinitions
                }
            }
            Write-Verbose "Release definition $ReleaseDefinitionName not found."
        } 
        elseif ($releaseDefinitions -ne $null) {
            return $releaseDefinitions
        }

        Write-Verbose "Release definition $ReleaseDefinitionId not found."
        
        return $null
    }
    END { }
}

