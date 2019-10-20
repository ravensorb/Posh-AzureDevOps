<#

.SYNOPSIS
Remove a variable/value to the specified Azure DevOps reelase pipeline

.DESCRIPTION
The command will remove a variable to the specified Azure DevOps reelase pipeline

.PARAMETER ReleaseDefinitionId
The id of the reelase definition to update (use on this OR the name parameter)

.PARAMETER ReleaseDefinitionName
The name of the build definition to update (use on this OR the id parameter)

.PARAMETER VariableName
Tha name of the variable to create/update

.PARAMETER All
Remove all variables in the library (VariableName is ignored when this is set)

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Add-AzDoReleasePipelineVariable -ProjectUrl https://dev.azure.com/<organizztion>/<project> -ReleaseDefinitionName <reelase defintiion name> -VariableName <variable name> -PAT <personal access token>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>

function Remove-AzDoReleasePipelineVariable()
{
    [CmdletBinding(
        DefaultParameterSetName="Name",
        SupportsShouldProcess=$True
    )]
    param
    (
        # Common Parameters
        [parameter(Mandatory=$false, ValueFromPipelinebyPropertyName=$true, ValueFromPipeline=$true)][PoshAzDo.AzDoConnectObject]$AzDoConnection,
        [parameter(Mandatory=$false)][string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [parameter(Mandatory=$false, ParameterSetName="Name", ValueFromPipelinebyPropertyName=$true)][string]$ReleaseDefinitionName,
        [parameter(Mandatory=$false, ParameterSetName="ID", ValueFromPipelinebyPropertyName=$true)][int]$ReleaseDefinitionId,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)][Alias("name")][string]$VariableName,
        [parameter(Mandatory=$false)][switch]$All
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

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "`tParameter Values"
        $PSBoundParameters.Keys | ForEach-Object { if ($Secret -and $_ -eq "VariableValue") { Write-Verbose "`t`tVariableValue = *******" } else { Write-Verbose "`t`t$_ = '$($PSBoundParameters[$_])'" }}
    }
    PROCESS
    {
        $definition = $null

        if ($ReleaseDefinitionId -ne $null -and $ReleaseDefinitionId -gt 0)
        {
            $definition = Get-AzDoReleaseDefinition -AzDoConnection $AzDoConnection -ReleaseDefinitionId $ReleaseDefinitionId -ExpandFields "variables"
        }
        elseif (-Not [string]::IsNullOrEmpty($ReleaseDefinitionName))
        {
            $definition = Get-AzDoReleaseDefinition -AzDoConnection $AzDoConnection -ReleaseDefinitionName $ReleaseDefinitionName -ExpandFields "variables"
        }

        if ($null -eq $definition) { throw "Could not find a valid release definition.  Check your parameters and try again";}

        [bool]$found = $false
        foreach($prop in $definition.variables.PSObject.Properties.Where{$_.MemberType -eq "NoteProperty" -and (($_.Name -eq $VariableName) -or $All)})
        {
            Write-Verbose "Removing Variable: $($prop.Name)"

            $definition.variables.PSObject.Properties.Remove($prop.Name)

            $found = $true
        }

        if (-Not $found)
        {
            Write-Verbose "Variable not found"

            return
        }
            
        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.ReleaseManagementUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/release/definitions/$($definition.id)"

        #$definition.source = "restApi"

        #Write-Verbose "Persist definition $definition."
        $body = $definition | ConvertTo-Json -Depth 10 -Compress

        Write-Verbose "---------BODY---------"
        Write-Verbose $body
        Write-Verbose "---------BODY---------"

        if (-Not $WhatIfPreference)
        {
            $response = Invoke-RestMethod $apiUrl -Method Put -Body $body -ContentType 'application/json' -Headers $AzDoConnection.HttpHeaders | Out-Null        
        }

        Write-Verbose "---------RESPONSE---------"
        Write-Verbose ($response | ConvertTo-Json -Depth 50 | Out-String)
        Write-Verbose "---------RESPONSE---------"
    }
    END
    {
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"

        return $true
    }
}

