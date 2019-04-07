<#

.SYNOPSIS
This commend provides accesss Release Pipeline Varaibles from Azure DevOps

.DESCRIPTION
The  command will retrieve all of the variables in a specific release pipeline

.PARAMETER ProjectUrl
The full url for the Azure DevOps Project.  For example https://<organization>.visualstudio.com/<project> or https://dev.azure.com/<organization>/<project>

.PARAMETER DefinitionId
The id of the release definition to update (use on this OR the name parameter)

.PARAMETER DefinitionName
The name of the release definition to update (use on this OR the id parameter)

.PARAMETER VariableName
Tha name of the variable to create/update

.PARAMETER VariableValue
The variable for the variable

.PARAMETER Secret
Indicates if the vaule should be stored as a "secret"

.PARAMETER VariableGroups
N/A

.PARAMETER Comment
A comment to add to the variable

.PARAMETER Reset
Indicates if the ENTIRE library should be reset. This means that ALL values are REMOVED. Use with caution

.PARAMETER Force
Indicates if the library group should be created if it doesn't exist

.PARAMETER PAT
A valid personal access token with at least read access for build definitions

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Add-AzDoReleasePipelineVariable -ProjectUrl https://dev.azure.com/<organizztion>/<project> -DefinitionName <release defintiion name> -VariableName <variable name> -VariableValue <varaible value> -Environment <env name> -PAT <personal access token>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>

function Add-AzDoReleasePipelineVariable()
{
    [CmdletBinding()]
    param
    (
        [string][parameter(Mandatory = $true)]$ProjectUrl,
        [int][parameter(ParameterSetName='Id',ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]$DefinitionId = $null,
        [string][parameter(ParameterSetName='Name',ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]$DefinitionName = $null,
        [string][parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][Alias("name")]$VariableName,
        [string][parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][Alias("value")]$VariableValue,
        [string][parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][Alias("env")]$EnvironmentName,
        [bool][parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]$Secret,
        [int[]]$VariableGroups,
        [string]$Comment,
        [switch]$Reset,
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

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "Parameter Values"
        $PSBoundParameters.Keys | ForEach-Object { if ($Secret -and $_ -eq "VariableValue") { Write-Verbose "VariableValue = *******" } else { Write-Verbose "$_ = '$($PSBoundParameters[$_])'" }}

        $headers = Get-AzDoHttpHeader -PAT $PAT -ApiVersion $ApiVersion 

        $ProjectUrl = Get-AzDoRmUrlFromProjectUrl -ProjectUrl $ProjectUrl
    }
    PROCESS
    {
        $definition = $null

        if ($DefinitionId -ne $null -and $DefinitionId -gt 0)
        {
            $definition = Get-AzDoReleaseDefinition -ProjectUrl $ProjectUrl -Id $DefinitionId -PAT $PAT
        }
        elseif (-Not [string]::IsNullOrEmpty($DefinitionName))
        {
            $definition = Get-AzDoReleaseDefinition -ProjectUrl $ProjectUrl -Name $DefinitionName -PAT $PAT -ExpandFields "Environments"
        }

        if ($definition -eq $null) { throw "Could not find a valid release definition.  Check your parameters and try again"; }

        if ($Reset)
        {
            foreach($environment in $definition.environments)
            {
                foreach($prop in $environment.variables.PSObject.Properties.Where{$_.MemberType -eq "NoteProperty"})
                {
                    $environment.variables.PSObject.Properties.Remove($prop.Name)
                }
            }

            foreach($prop in $definition.variables.PSObject.Properties.Where{$_.MemberType -eq "NoteProperty"})
            {
                $definition.variables.PSObject.Properties.Remove($prop.Name)
            }

            $definition.variableGroups = @()
        }

        $apiUrl = Get-AzDoApiUrl -ProjectUrl $ProjectUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/release/definitions"

        $value = @{value=$VariableValue}
    
        if ($Secret)
        {
            $value.Add("isSecret", $true)
        }

        if ($EnvironmentName)
        {
            $environment = $definition.environments.Where{$_.name -like $EnvironmentName}

            if($environment)
            {
                $environment.variables | Add-Member -Name $VariableName -MemberType NoteProperty -Value $value -Force
            }
            else
            {
                Write-Warning "Environment '$($environment.name)' not found in the given release"
            }
        }
        else
        {
            $definition.variables | Add-Member -Name $VariableName -MemberType NoteProperty -Value $value -Force
        }

        $definition.source = "restApi"

        if ($Comment)
        {
            $definition | Add-Member -Name "comment" -MemberType NoteProperty -Value $Comment
        }
        
        if ($VariableGroups)
        {
            foreach($variable in $VariableGroups)
            {
                if ($definition.variableGroups -notcontains $variable)
                {
                    $definition.variableGroups += $variable
                }
            }
        }

        $body = $definition | ConvertTo-Json -Depth 10 -Compress

        $response = Invoke-RestMethod $apiUrl -Method Put -Body $body -ContentType 'application/json' -Headers $headers 
    }
    END
    {
        Write-Verbose "Response: $($response.id)"

        $response
    }
}

