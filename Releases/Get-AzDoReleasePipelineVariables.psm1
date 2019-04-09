<#

.SYNOPSIS
This commend provides accesss Release Pipeline Varaibles from Azure DevOps

.DESCRIPTION
The  command will retrieve all of the variables in a specific release pipeline

.PARAMETER ProjectUrl
The full url for the Azure DevOps Project.  For example https://<organization>.visualstudio.com/<project> or https://dev.azure.com/<organization>/<project>

.PARAMETER ReleaseDefinitionName
The name of the release definition to retrieve (use on this OR the id parameter)

.PARAMETER ReleaseDefinitionId
The id of the release definition to retrieve (use on this OR the name parameter)

.PARAMETER VariableName
The name of the variable in the release definition to retrieve

.PARAMETER PAT
A valid personal access token with at least read access for release definitions

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
        [string][parameter(Mandatory = $true, ValueFromPipelinebyPropertyName = $true)]$ProjectUrl,
        [int][parameter(ParameterSetName='Id', ValueFromPipelineByPropertyName = $true)]$ReleaseDefinitionId = $null,
        [string][parameter(ParameterSetName='Name', ValueFromPipelineByPropertyName = $true)]$ReleaseDefinitionName = $null,
        [string][parameter(ValueFromPipelineByPropertyName = $true)][Alias("name")]$VariableName,
        [string][parameter(ValueFromPipelineByPropertyName = $true)][Alias("env")]$EnvironmentName = $null,
        [string][parameter(Mandatory = $true, ValueFromPipelinebyPropertyName = $true)]$PAT,
        [string]$ApiVersion = $global:AzDoApiVersion
    )
    BEGIN
    {
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }        

        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0"}

        if ([string]::IsNullOrEmpty($ProjectUrl)) { throw "Invalid Project Url";  }
        if ([string]::IsNullOrEmpty($EnvironmentName)) { $EnvironmentName = "*" }
      
        if ($ReleaseDefinitionId -eq $null -and [string]::IsNullOrEmpty($ReleaseDefinitionName)) { throw "Definition ID or Name must be specified"; }

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "Parameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "$_ = '$($PSBoundParameters[$_])'" }

        $headers = Get-AzDoHttpHeader -PAT $PAT -ApiVersion $ApiVersion 

        $ProjectUrl = Get-AzDoRmUrlFromProjectUrl $ProjectUrl
    }
    PROCESS
    {
        $definition = $null

        if ($ReleaseDefinitionId -ne $null -and $ReleaseDefinitionId -gt 0)
        {
            $definition = Get-AzDoReleaseDefinition -ProjectUrl $ProjectUrl -ReleaseDefinitionId $ReleaseDefinitionId -PAT $PAT
        }
        elseif ($ReleaseDefinitionName -ne $null)
        {
            $definition = Get-AzDoReleaseDefinition -ProjectUrl $ProjectUrl -ReleaseDefinitionName $ReleaseDefinitionName -PAT $PAT
        }

        if ($definition -eq $null) { throw "Could not find a valid release definition.  Check your parameters and try again"}

        $apiUrl = Get-AzDoApiUrl -ProjectUrl $ProjectUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/release/definitions/$($definition.Id)" -QueryStringParams "expand=Environments"
        
        $definition = Invoke-RestMethod $apiUrl -Headers $headers

        Write-Verbose "---------RELEASE DEFINITION---------"
        Write-Verbose $definition
        Write-Verbose "---------RELEASE DEFINITION---------"

        if (-Not $definition.variables) {
            Write-Verbose "No variables definied"
            return $null
        }

        Write-Verbose "---------RELEASE VARAIBLES---------"
        $definition.variables.PSObject.Properties | Write-Verbose
        Write-Verbose "---------RELEASE VARAIBLES---------"

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

