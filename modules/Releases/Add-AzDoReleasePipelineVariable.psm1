<#

.SYNOPSIS
This commend provides accesss Release Pipeline Varaibles from Azure DevOps

.DESCRIPTION
The  command will retrieve all of the variables in a specific release pipeline

.PARAMETER ReleaseDefinitionId
The id of the release definition to update (use on this OR the name parameter)

.PARAMETER ReleaseDefinitionName
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

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Add-AzDoReleasePipelineVariable -ProjectUrl https://dev.azure.com/<organizztion>/<project> -ReleaseDefinitionName <release defintiion name> -VariableName <variable name> -VariableValue <varaible value> -Environment <env name> -PAT <personal access token>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>

function Add-AzDoReleasePipelineVariable()
{
    [CmdletBinding()]
    param
    (
        # Common Parameters
        [PoshAzDo.AzDoConnectObject][parameter(ValueFromPipelinebyPropertyName = $true, ValueFromPipeline = $true)]$AzDoConnection,
        [string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [int][parameter(ParameterSetName='Id', ValueFromPipelineByPropertyName = $true)]$ReleaseDefinitionId = $null,
        [string][parameter(ParameterSetName='Name', ValueFromPipelineByPropertyName = $true)]$ReleaseDefinitionName = $null,
        [string][parameter(ValueFromPipelineByPropertyName = $true)][Alias("name")]$VariableName,
        [string][parameter(ValueFromPipelineByPropertyName = $true)][Alias("value")]$VariableValue,
        [string][parameter(ValueFromPipelineByPropertyName = $true)][Alias("env")]$EnvironmentName,
        [bool][parameter(ValueFromPipelineByPropertyName = $true)]$Secret,
        [int[]]$VariableGroups,
        [string]$Comment,
        [switch]$Reset
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

        if ([string]::IsNullOrEmpty($VariableName) -and ($null -eq $VariableGroups -or $VariableGroups.Count -eq 0))
        {
            throw "Please specifiy a variable name or at least one variable group"
        }

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "Parameter Values"
        $PSBoundParameters.Keys | ForEach-Object { if ($Secret -and $_ -eq "VariableValue") { Write-Verbose "VariableValue = *******" } else { Write-Verbose "$_ = '$($PSBoundParameters[$_])'" }}        
    }
    PROCESS
    {
        $definition = $null

        if ($ReleaseDefinitionId -ne $null -and $ReleaseDefinitionId -gt 0)
        {
            $definition = Get-AzDoReleaseDefinition -AzDoConnection $AzDoConnection -ReleaseDefinitionId $ReleaseDefinitionId -ExpandFields "Environments"
        }
        elseif (-Not [string]::IsNullOrEmpty($ReleaseDefinitionName))
        {
            $definition = Get-AzDoReleaseDefinition -AzDoConnection $AzDoConnection -ReleaseDefinitionName $ReleaseDefinitionName -ExpandFields "Environments"
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

        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.ReleaseManagementUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/release/definitions"

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

        $response = Invoke-RestMethod $apiUrl -Method Put -Body $body -ContentType 'application/json' -Headers $AzDoConnection.HttpHeaders 
    }
    END
    {
        Write-Verbose "Response: $($response.id)"

        $response
    }
}

