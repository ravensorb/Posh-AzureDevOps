<#

.SYNOPSIS
Add a new variable/value to the specified Azure DevOps build pipeline

.DESCRIPTION
The command will add a variable to the specified Azure DevOps build pipeline

.PARAMETER ProjectUrl
The full url for the Azure DevOps Project.  For example https://<organization>.visualstudio.com/<project> or https://dev.azure.com/<organization>/<project>

.PARAMETER BuildDefinitionId
The id of the build definition to update (use on this OR the name parameter)

.PARAMETER BuildDefinitionName
The name of the build definition to update (use on this OR the id parameter)

.PARAMETER VariableName
Tha name of the variable to create/update

.PARAMETER VariableValue
The variable for the variable

.PARAMETER Secret
Indicates if the vaule should be stored as a "secret"

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
Add-AzDoBuildPipelineVariable -ProjectUrl https://dev.azure.com/<organizztion>/<project> -BuildDefinitionName <build defintiion name> -VariableName <variable name> -VariableValue <varaible value> -Environment <env name> -PAT <personal access token>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>

function Add-AzDoBuildPipelineVariable()
{
    [CmdletBinding(
        DefaultParameterSetName='Name'
    )]
    param
    (
        # Common Parameters
        [PoshAzDo.AzDoConnectObject][parameter(ValueFromPipelinebyPropertyName = $true, ValueFromPipeline = $true)]$AzDoConnection,
        [string][parameter(ValueFromPipelinebyPropertyName = $true)]$ProjectUrl,
        [string][parameter(ValueFromPipelinebyPropertyName = $true)]$PAT,
        [string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [int][parameter(ParameterSetName='Id', ValueFromPipelineByPropertyName = $true)]$BuildDefinitionId = $null,
        [string][parameter(ParameterSetName='Name', ValueFromPipelineByPropertyName = $true)]$BuildDefinitionName = $null,
        [string][parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]$VariableName,
        [string][parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]$VariableValue,
        [bool][parameter(ValueFromPipelineByPropertyName = $true)]$Secret,
        [int[]]$VariableGroups,
        [string]$Comment

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
            if ([string]::IsNullOrEmpty($ProjectUrl))
            {
                $AzDoConnection = Get-AzDoActiveConnection

                if ($AzDoConnection -eq $null) { throw "AzDoConnection or ProjectUrl must be valid" }
            }
            else 
            {
                $AzDoConnection = Connect-AzDo -ProjectUrl $ProjectUrl -PAT $PAT -LocalOnly
            }
        }

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "`tParameter Values"
        $PSBoundParameters.Keys | ForEach-Object { if ($Secret -and $_ -eq "VariableValue") { Write-Verbose "`t`tVariableValue = *******" } else { Write-Verbose "`t`t$_ = '$($PSBoundParameters[$_])'" }}
    
         
    }
    PROCESS
    {
        $definition = $null

        if ($BuildDefinitionId -ne $null -and $BuildDefinitionId -gt 0)
        {
            $definition = Get-AzDoBuildDefinition -AzDoConnection $AzDoConnection -BuildDefinitionId $BuildDefinitionId -ExpandFields "variables"
        }
        elseif (-Not [string]::IsNullOrEmpty($BuildDefinitionName))
        {
            $definition = Get-AzDoBuildDefinition -AzDoConnection $AzDoConnection -BuildDefinitionName $BuildDefinitionName -ExpandFields "variables"
        }

        if ($definition -eq $null) { throw "Could not find a valid build definition.  Check your parameters and try again";}

        if ($Reset)
        {
            foreach($prop in $definition.variables.PSObject.Properties.Where{$_.MemberType -eq "NoteProperty"})
            {
                $definition.variables.PSObject.Properties.Remove($prop.Name)
            }

            $definition.variableGroups = @()
        }
        
        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.ProjectUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/build/definitions/$($definition.id)"

        $value = @{value=$VariableValue}
    
        if ($Secret)
        {
            $value.Add("isSecret", $true)
        }

        $definition.variables | Add-Member -Name $VariableName -MemberType NoteProperty -Value $value -Force

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

    }
    END
    {
        #$definition.source = "restApi"

        $body = $definition | ConvertTo-Json -Depth 10 -Compress

        $response = Invoke-RestMethod $apiUrl -Method Put -Body $body -ContentType 'application/json' -Headers $AzDoConnection.HttpHeaders

        Write-Verbose "Response: $($response.id)"

        $response
    }
}

