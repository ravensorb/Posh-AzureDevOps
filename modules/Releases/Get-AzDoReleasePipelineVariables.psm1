<#

.SYNOPSIS
This commend provides accesss Release Pipeline Varaibles from Azure DevOps

.DESCRIPTION
The  command will retrieve all of the variables in a specific release pipeline

.PARAMETER ReleaseDefinitionName
The name of the release definition to retrieve (use on this OR the id parameter)

.PARAMETER ReleaseDefinitionId
The id of the release definition to retrieve (use on this OR the name parameter)

.PARAMETER VariableName
The name of the variable in the release definition to retrieve

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Get-AzDoReleasePipelineVariables -ProjectUrl https://dev.azure.com/<organizztion>/<project> -ReleaseDefinitionName <release defintiion name> -VariableName <variable name> -PAT <personal access token>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Get-AzDoReleasePipelineVariables()
{
    [CmdletBinding(
        DefaultParameterSetName='Name'
    )]
    param
    (
        # Common Parameters
        [PoshAzDo.AzDoConnectObject][parameter(ValueFromPipelinebyPropertyName = $true, ValueFromPipeline = $true)]$AzDoConnection,
        [string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [int][parameter(ParameterSetName='Id', ValueFromPipelineByPropertyName = $true)][Alias("id")]$ReleaseDefinitionId = $null,
        [string][parameter(ParameterSetName='Name', ValueFromPipelineByPropertyName = $true)][Alias("name")]$ReleaseDefinitionName = $null,
        [string][parameter(ValueFromPipelineByPropertyName = $true)]$VariableName,
        [string][parameter(ValueFromPipelineByPropertyName = $true)]$EnvironmentName = $null
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

        if (-Not $definition.variables) {
            Write-Verbose "No variables definied"
            return $null
        }

        Write-Verbose "---------RELEASE VARAIBLES BEGIN---------"
        $definition.variables.PSObject.Properties | Write-Verbose
        Write-Verbose "---------RELEASE VARAIBLES END---------"

        $variables = @()

        if (-Not [string]::IsNullorEmpty($EnvironmentName)) 
        {
            Write-Verbose "Getting ariables for Environment $EnvironmentName"
            foreach($environment in $definition.environments)
            {
                if ($enviroEnvironmentNamenment -eq "*" -or $environment -like "*$EnvironmentName*") {
                    $environment.variables.PSObject.Properties | ? { $_.MemberType -eq "NoteProperty"} | % { 
                        Write-Verbose $_.Value
                        $variables += [pscustomobject]@{
                            Name = $_.Name;
                            Value = $_.Value.value;
                            Environment = $environment.Name;
                        }
                    }
                }
            }
        }

        $definition.variables.PSObject.Properties | ? { $_.MemberType -eq "NoteProperty"} | % { 
            $variables += [pscustomobject]@{
                Name = $_.Name;
                Value = $_.Value;
                Environment = "Release";
            }
        };

        $variables
    }
    END
    {

    }
}

