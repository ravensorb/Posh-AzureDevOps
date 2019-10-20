<#

.SYNOPSIS
This commend provides accesss Build Pipeline Varaibles from Azure DevOps

.DESCRIPTION
The  command will retrieve all of the variables in a specific build pipeline

.PARAMETER BuildDefinitionName
The name of the build definition to retrieve (use on this OR the id parameter)

.PARAMETER BuildDefinitionId
The id of the build definition to retrieve (use on this OR the name parameter)

.PARAMETER VariableName
The name of the variable in the build definition to retrieve

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Get-AzDoBuildPipelineVariables -BuildDefinitionName <build defintiion name> -VariableName <variable name>

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
        # Common Parameters
        [parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelinebyPropertyName=$true)][PoshAzDo.AzDoConnectObject]$AzDoConnection,
        [parameter(Mandatory=$false)][string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [parameter(Mandatory=$false, ParameterSetName="ID", ValueFromPipelineByPropertyName=$true)][int]$BuildDefinitionId = $null,
        [parameter(Mandatory=$false, ParameterSetName="Name", ValueFromPipelineByPropertyName=$true)][string]$BuildDefinitionName = $null
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

        if (-Not (Test-Path varaible:$AzDoConnection) -and $null -eq $AzDoConnection)
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
        $definition = $null

        if ($BuildDefinitionId -ne $null -and $BuildDefinitionId -gt 0)
        {
            $definition = Get-AzDoBuildDefinition -AzDoConnection $AzDoConnection -BuildDefinitionId $BuildDefinitionId
        }
        elseif (-Not [string]::IsNullOrEmpty($BuildDefinitionName))
        {
            $definition = Get-AzDoBuildDefinition -AzDoConnection $AzDoConnection -BuildDefinitionName $BuildDefinitionName 
        }

        if ($null -eq $definition) { Write-Error -ErrorAction $errorPreference -Message "Could not find a valid build definition.  Check your parameters and try again"; }

        $apiParams = @()

        $apiParams += "Expand=parameters"

        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.ProjectUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/build/definitions/$($definition.Id)" -QueryStringParams $apiParams

        $definition = Invoke-RestMethod $apiUrl -Headers $AzDoConnection.HttpHeaders

        Write-Verbose "---------BUILD DEFINITION---------"
        Write-Verbose ($definition| ConvertTo-Json -Depth 50 | Out-String)
        Write-Verbose "---------BUILD DEFINITION---------"

        if (-Not $definition.variables) {
            Write-Verbose "No variables definied"
            return $null
        }

        #Write-Verbose "---------VARIABLE---------"
        #Write-Verbose ($definition.variables| ConvertTo-Json -Depth 50 | Out-String)
        #$definition.variables.PSObject.Properties | Write-Verbose
        #Write-Verbose "---------VARIABLES---------"

        $variables = @()

        Write-Verbose "Build Variables"
        $definition.variables.PSObject.Properties | Where-Object { $_.MemberType -eq "NoteProperty"} | ForEach-Object { 
            Write-Verbose "`t$($_.Name) => $($_.Value)"

            $variables += [pscustomobject]@{
                Name = $_.Name;
                Value = $_.Value.value;
                Secret = $_.Value.isSecret;
                AllowOverride = $_.Value.allowOverride;
            }
        }

        $variables
    }
    END
    {
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}

