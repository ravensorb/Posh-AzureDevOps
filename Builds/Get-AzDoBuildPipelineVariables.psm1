<#

.SYNOPSIS
This commend provides accesss Build Pipeline Varaibles from Azure DevOps

.DESCRIPTION
The  command will retrieve all of the variables in a specific build pipeline

.PARAMETER ProjectUrl
The full url for the Azure DevOps Project.  For example https://<organization>.visualstudio.com/<project> or https://dev.azure.com/<organization>/<project>

.PARAMETER DefinitionName
The name of the build definition to retrieve (use on this OR the id parameter)

.PARAMETER DefinitionId
The id of the build definition to retrieve (use on this OR the name parameter)

.PARAMETER VariableName
The name of the variable in the build definition to retrieve

.PARAMETER PAT
A valid personal access token with at least read access for build definitions

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Get-AzDoBuildPipelineVariables -ProjectUrl https://dev.azure.com/<organizztion>/<project> -DefinitionName <build defintiion name> -VariableName <variable name> -PAT <personal access token>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Get-AzDoBuildPipelineVariables()
{
    [CmdletBinding(
        DefaultParameterSetName='Name'
    )]
    param
    (
        [string][parameter(Mandatory = $true)]$ProjectUrl,
        [int][parameter(ParameterSetName='Id',ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]$DefinitionId = $null,
        [string][parameter(ParameterSetName='Name',ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]$DefinitionName = $null,
        [string]$PAT,
        [string]$ApiVersion = $global:AzDoApiVersion
    )
    BEGIN
    {
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }        
    
        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0"}

        if ([string]::IsNullOrEmpty($ProjectUrl)) { throw "Invalid Project Url"; }

        if ($DefinitionId -eq $null -and [string]::IsNullOrEmpty($DefinitionName)) { throw "Definition ID or Name must be specified"; }

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "`tParameter Values"

        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "`t`t$_ = '$($PSBoundParameters[$_])'" }

        $headers = Get-AzDoHttpHeader -PAT $PAT -ApiVersion $ApiVersion 
    }
    PROCESS
    {
        $definition = $null

        if ($DefinitionId -ne $null -and $DefinitionId -gt 0)
        {
            $definition = Get-AzDoBuildDefinition -ProjectUrl $ProjectUrl -Id $DefinitionId -PAT $PAT 
        }
        elseif (-Not [string]::IsNullOrEmpty($DefinitionName))
        {
            $definition = Get-AzDoBuildDefinition -ProjectUrl $ProjectUrl -Name $DefinitionName -PAT $PAT
        }

        if ($definition -eq $null) { throw "Could not find a valid build definition.  Check your parameters and try again"; }

        $apiUrl = Get-AzDoApiUrl -ProjectUrl $ProjectUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/build/definitions/$($definition.Id)" -QueryStringParams "Expand=parameters"

        $definition = Invoke-RestMethod $apiUrl -Headers $headers

        Write-Verbose "---------BUILD DEFINITION---------"
        Write-Verbose $definition
        Write-Verbose "---------BUILD DEFINITION---------"

        if (-Not $definition.variables) {
            Write-Verbose "No variables definied"
            return $null
        }

        # Write-Verbose "---------BUILD VARAIBLES---------"
        # $definition.variables.PSObject.Properties | Write-Verbose
        # Write-Verbose "---------BUILD VARAIBLES---------"

        $variables = @()

        Write-Verbose "Build Variables"
        $definition.variables.PSObject.Properties | ? { $_.MemberType -eq "NoteProperty"} | % { 
            Write-Verbose "`t$($_.Name) => $($_.Value)"

            $variables += [pscustomobject]@{
                Name = $_.Name;
                Value = $_.Value.value;
                Secret = $_.Value.isSecret;
                AllowOverride = $_.Value.allowOverride;
            }
        };
    }
    END
    {
        $variables
    }
}

