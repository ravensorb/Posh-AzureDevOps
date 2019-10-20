<#

.SYNOPSIS
Retrieve the build for the specified build defintion 

.DESCRIPTION
The command will retrieve a full build details for the specified definition (if it exists) 

.PARAMETER BuildDefinitionName
The name of the build definition to retrieve (use on this OR the id parameter)

.PARAMETER BuildDefinitionId
The id of the build definition to retrieve (use on this OR the name parameter)

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Get-AzDoBuilds -BuildDefinitionName <build defintiion name>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Get-AzDoBuilds()
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
        [parameter(Mandatory=$false, ParameterSetName="Name", ValueFromPipelineByPropertyName=$true)][string]$BuildDefinitionName,
        [parameter(Mandatory=$false, ParameterSetName="ID", ValueFromPipelineByPropertyName=$true)][int]$BuildDefinitionId,
        [parameter(Mandatory=$false)][int]$Count = 1
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

        if (-Not (Test-Path varaible:$AzDoConnection) -and $AzDoConnection -eq $null)
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
        $buildDefinition = $null

        if ($BuildDefinitionId -ne $null -and $BuildDefinitionId -ne 0) 
        {
            $buildDefinition = Get-AzDoBuildDefinition -AzDoConnection $AzDoConnection -BuildDefinitionId $BuildDefinitionId 
        }
        elseif (-Not [string]::IsNullOrEmpty($BuildDefinitionName))
        {
            $buildDefinition = Get-AzDoBuildDefinition -AzDoConnection $AzDoConnection -BuildDefinitionName $BuildDefinitionName 
        }

        if (-Not $buildDefinition)
        {
            Write-Error -ErrorAction $errorPreference -Message "Build defintion specified was not found"
        }
        
        $apiParams = @()

        $apiParams += "`$top=$($Count)"
        $apiParams += "definitions=$($definition.Id)"

        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.ProjectUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/build/builds" -QueryStringParams $apiParams

        $builds = Invoke-RestMethod $apiUrl -Headers $AzDoConnection.HttpHeaders

        Write-Verbose "---------BUILDS---------"
        Write-Verbose ($builds | ConvertTo-Json -Depth 50 | Out-String)
        Write-Verbose "---------BUILDS---------"

        #Write-Verbose "Build status $($build.id) not found."
        
        $builds.value
    }
    END 
    { 
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}

