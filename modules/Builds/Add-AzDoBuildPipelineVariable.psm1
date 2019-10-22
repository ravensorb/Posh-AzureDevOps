<#

.SYNOPSIS
Add a new variable/value to the specified Azure DevOps build pipeline

.DESCRIPTION
The command will add a variable to the specified Azure DevOps build pipeline

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
Indicates if the ENTIRE variable group should be reset. This means that ALL values are REMOVED. Use with caution

.PARAMETER Force
Indicates if the variable group should be created if it doesn't exist

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Add-AzDoBuildPipelineVariable -BuildDefinitionName <build defintiion name> -VariableName <variable name> -VariableValue <varaible value> -Environment <env name>

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
        [parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelinebyPropertyName=$true)][PoshAzDo.AzDoConnectObject]$AzDoConnection,
        [parameter(Mandatory=$false)][string]$ApiVersion = $global:AzDoApiVersion,
        
        # Module Parameters
        [parameter(Mandatory=$false, ParameterSetName="ID", ValueFromPipelineByPropertyName=$true)][int]$BuildDefinitionId = $null,
        [parameter(Mandatory=$false, ParameterSetName="Name", ValueFromPipelineByPropertyName=$true)][string]$BuildDefinitionName = $null,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)][string]$VariableName,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)][string]$VariableValue,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)][bool]$Secret,
        [parameter(Mandatory=$false)][int[]]$VariableGroups,
        [parameter(Mandatory=$false)][string]$Comment

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
            $AzDoConnection = Get-AzDoActiveConnection

            if ($AzDoConnection -eq $null) { Write-Error -ErrorAction $errorPreference -Message "AzDoConnection or ProjectUrl must be valid" }
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

        if ($null -eq $definition) { Write-Error -ErrorAction $errorPreference -Message "Could not find a valid build definition.  Check your parameters and try again";}

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

        #$definition.source = "restApi"

        $body = $definition | ConvertTo-Json -Depth 50 -Compress

        Write-Verbose "---------BODY---------"
        Write-Verbose $body
        Write-Verbose "---------BODY---------"

        if (-Not $WhatIfPreference)
        {
            $response = Invoke-RestMethod $apiUrl -Method Put -Body $body -ContentType 'application/json' -Headers $AzDoConnection.HttpHeaders
        }

        Write-Verbose "---------RESPONSE---------"
        Write-Verbose ($response | ConvertTo-Json -Depth 50 | Out-String)
        Write-Verbose "---------RESPONSE---------"

        $response
    }
    END
    {
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}

