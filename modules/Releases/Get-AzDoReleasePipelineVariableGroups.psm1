<#

.SYNOPSIS
Retreives the variable groups associated with the specified release defintion

.DESCRIPTION
The command will retrieve all of the variables groups assocaited with a specific release pipeline

.PARAMETER AzDoConnection
A valid Azure DevOps Connection object

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.PARAMETER ReleaseDefinitionName
The name of the release definition to retrieve (use on this OR the id parameter)

.PARAMETER ReleaseDefinitionId
The id of the release definition to retrieve (use on this OR the name parameter)

.EXAMPLE
Get-AzDoReleasePipelineVariableGroups -ProjectUrl https://dev.azure.com/<organizztion>/<project> -ReleaseDefinitionName <release defintiion name> -PAT <personal access token>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Get-AzDoReleasePipelineVariableGroups()
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
        [parameter(Mandatory=$false, ValueFromPipelinebyPropertyName=$true)][string]$EnvironmentName = $null
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

        if ([string]::IsNullOrEmpty($EnvironmentName)) { $EnvironmentName = "*" }
      
        if ($ReleaseDefinitionId -eq $null -and [string]::IsNullOrEmpty($ReleaseDefinitionName)) { throw "Definition ID or Name must be specified"; }

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "Parameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "$_ = '$($PSBoundParameters[$_])'" }            
    }
    PROCESS
    {
        $apiParams = @()

        $definition = $null

        if ($ReleaseDefinitionId -ne $null -and $ReleaseDefinitionId -gt 0)
        {
            $definition = Get-AzDoReleaseDefinition -AzDoConnection $AzDoConnection -ReleaseDefinitionId $ReleaseDefinitionId
        }
        elseif ($ReleaseDefinitionName -ne $null)
        {
            $definition = Get-AzDoReleaseDefinition -AzDoConnection $AzDoConnection -ReleaseDefinitionName $ReleaseDefinitionName
        }

        if ($definition -eq $null) { throw "Could not find a valid release definition.  Check your parameters and try again"}

        $apiParams += "expand=Environments,variablegroups"
        
        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.ReleaseManagementUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/release/definitions/$($definition.Id)" -QueryStringParams $apiParams
        
        $definition = Invoke-RestMethod $apiUrl -Headers $AzDoConnection.HttpHeaders

        Write-Verbose "---------RELEASE DEFINITION BEGIN---------"
        Write-Verbose $definition
        Write-Verbose "---------RELEASE DEFINITION END---------"

        $variableGroups = @()

        if (-Not [string]::IsNullorEmpty($EnvironmentName)) 
        {
            Write-Verbose "Getting ariables for Environment $EnvironmentName"
            foreach($environment in $definition.environments)
            {
                Write-Verbose "---------RELEASE $($environment.Name) VARAIBLES BEGIN---------"
                Write-Verbose "Variable Group Count: $($environment.variableGroups.Count)"
                $definition.variableGroups | Write-Verbose
                Write-Verbose "---------RELEASE $($environment.Name) VARAIBLES END---------"        
        
                if ($enviroEnvironmentNamenment -eq "*" -or $environment -like "*$EnvironmentName*") {
                    $environment.variableGroups | % { 
                        $variableGroup = Get-AzDoLibraryVariableGroup -AzDoConnection $AzDoConnection -VariableGroupId $($_)
                        
                        $variableGroups += [pscustomobject]@{
                            ID = $variableGroup.id;
                            Name = $variableGroup.name;
                            Environment = $environment.Name;
                        }
                    }
                }
            }
        }

        Write-Verbose "---------RELEASE VARAIBLES BEGIN---------"
        Write-Verbose "Variable Group Count: $($definition.variableGroups.Count)"
        $definition.variableGroups | Write-Verbose
        Write-Verbose "---------RELEASE VARAIBLES END---------"

        $definition.variableGroups | % { 
            $variableGroup = Get-AzDoLibraryVariableGroup -AzDoConnection $AzDoConnection -VariableGroupId $($_)

            $variableGroups += [pscustomobject]@{
                ID = $variableGroup.id;
                Name = $variableGroup.name;
                Environment = "Release";
            }
        };

        $variableGroups
    }
    END
    {

    }
}

