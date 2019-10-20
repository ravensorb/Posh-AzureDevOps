    <#

.SYNOPSIS
This command provides accesss Build Defintiions from Azure DevOps

.DESCRIPTION
The command will retrieve a full build definition (if it exists) 

.PARAMETER BuildDefinitionName
The name of the build definition to retrieve (use on this OR the id parameter)

.PARAMETER BuildDefinitionId
The id of the build definition to retrieve (use on this OR the name parameter)

.PARAMETER ExpandFields
A common seperated list of fields to expand

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Get-AzDoBuildDefinition -BuildDefinitionName <build defintiion name>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Get-AzDoBuildDefinition()
{
    [CmdletBinding(
        DefaultParameterSetName='Name'
    )]
    param
    (
        # Common Parameters
        [parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelinebyPropertyName=$true)][PoshAzDo.AzDoConnectObject]$AzDoConnection,
        [parameter(Mandatory=$false)][string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [parameter(Mandatory=$false, ParameterSetName="Name", ValueFromPipeline=$true, ValueFromPipelinebyPropertyName=$true)][string][Alias("name")]$BuildDefinitionName,
        [parameter(Mandatory=$false, ParameterSetName="ID", ValueFromPipeline=$true, ValueFromPipelinebyPropertyName=$true)][int][Alias("id")]$BuildDefinitionId,
        [parameter(Mandatory=$false)][string]$ExpandFields
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

        if ($BuildDefinitionId -eq $null -and [string]::IsNullOrEmpty($BuildDefinitionName)) { Write-Error -ErrorAction $errorPreference -Message "Definition ID or Name must be specified"; }

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "`tParameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "`t`t$_ = '$($PSBoundParameters[$_])'" }        
    }
    PROCESS
    {
        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.ProjectUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/build/definitions"

        $apiParams = @()

        if (-Not [string]::IsNullOrEmpty($ExpandFields)) 
        {
            $apiParams += "Expand=$($ExpandFields)"
        }

        if ($BuildDefinitionId -ne $null -and $BuildDefinitionId -ne 0) 
        {
            $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.ProjectUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/build/definitions/$($BuildDefinitionId)" -QueryStringParams $apiParams
        }
        else 
        {
            $apiParams += "searchText=$($BuildDefinitionName)"

            $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.ProjectUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/build/definitions" -QueryStringParams $apiParams
        }

        $buildDefinitions = Invoke-RestMethod $apiUrl -Headers $AzDoConnection.HttpHeaders
        
        Write-Verbose "---------BUILD DEFINITIONS---------"
        Write-Verbose ($buildDefinitions| ConvertTo-Json -Depth 50 | Out-String)
        Write-Verbose "---------BUILD DEFINITIONS---------"

        if ($null -ne $buildDefinitions.count)
        {   
            if (-Not [string]::IsNullOrEmpty($BuildDefinitionName))
            {
                foreach($bd in $buildDefinitions.value)
                {
                    if ($bd.name -like $BuildDefinitionName){
                        Write-Verbose "Release Defintion Found $($bd.name) found."

                        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.ProjectUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/build/definitions/$($bd.id)" -QueryStringParams $apiParams
                        $buildDefinition = Invoke-RestMethod $apiUrl -Headers $AzDoConnection.HttpHeaders

                        Write-Verbose "---------BUILD DEFINITION---------"
                        Write-Verbose ($buildDefinitions| ConvertTo-Json -Depth 50 | Out-String)
                        Write-Verbose "---------BUILD DEFINITION---------"
                
                        return $buildDefinition
                    }                     
                }
            }
            else {
                return $buildDefinitions.value
            }

            Write-Verbose "Build definition $BuildDefinitionName not found."

            return $null
        } 
        elseif ($null -ne $buildDefinitions) {
            return $buildDefinitions
        }

        Write-Verbose "Build definition $BuildDefinitionId not found."
        
        return $null
    }
    END 
    { 
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}

