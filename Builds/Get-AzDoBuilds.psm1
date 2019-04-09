<#

.SYNOPSIS
Retrieve the build for the specified build defintion 

.DESCRIPTION
The command will retrieve a full build details for the specified definition (if it exists) 

.PARAMETER ProjectUrl
The full url for the Azure DevOps Project.  For example https://<organization>.visualstudio.com/<project> or https://dev.azure.com/<organization>/<project>

.PARAMETER BuildDefinitionName
The name of the build definition to retrieve (use on this OR the id parameter)

.PARAMETER BuildDefinitionId
The id of the build definition to retrieve (use on this OR the name parameter)

.PARAMETER PAT
A valid personal access token with at least read access for build definitions

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Get-AzDoBuilds -ProjectUrl https://dev.azure.com/<organizztion>/<project> -BuildDefinitionName <build defintiion name> -PAT <personal access token>

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
        [string][parameter(Mandatory = $true, ValueFromPipelinebyPropertyName = $true)]$ProjectUrl,
        [string][parameter(ParameterSetName='Name', ValueFromPipelinebyPropertyName = $true)]$BuildDefinitionName,
        [int][parameter(ParameterSetName='ID', ValueFromPipelinebyPropertyName = $true)]$BuildDefinitionId,
        [int]$Count = 1,
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

        if ($BuildDefinitionId -eq $null -and [string]::IsNullOrEmpty($BuildDefinitionName)) { throw "Definition ID or Name must be specified"; }

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "`tParameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "`t`t$_ = '$($PSBoundParameters[$_])'" }

        $headers = Get-AzDoHttpHeader -PAT $PAT -ApiVersion $ApiVersion
    }
    PROCESS
    {
        $buildDefinition = $null

        if ($BuildDefinitionId -ne $null -and $BuildDefinitionId -ne 0) 
        {
            $buildDefinition = Get-AzDoBuildDefinition -ProjectUrl $ProjectUrl -PAT $PAT -BuildDefinitionId $BuildDefinitionId 
        }
        elseif (-Not [string]::IsNullOrEmpty($BuildDefinitionName))
        {
            $buildDefinition = Get-AzDoBuildDefinition -ProjectUrl $ProjectUrl -PAT $PAT -BuildDefinitionName $BuildDefinitionName 
        }

        if (-Not $buildDefinition)
        {
            throw "Build defintion specified was not found"
        }
        
        $apiParams = @()

        $apiParams += "`$top=$($Count)"
        $apiParams += "definitions=$($definition.Id)"

        $apiUrl = Get-AzDoApiUrl -ProjectUrl $ProjectUrl -BaseApiPath "/_apis/build/builds" -QueryStringParams $apiParams -ApiVersion $ApiVersion

        $builds = Invoke-RestMethod $apiUrl -Headers $headers

        Write-Verbose "---------BUILDS---------"
        Write-Verbose $builds
        Write-Verbose "---------BUILDS---------"

        #Write-Verbose "Build status $($build.id) not found."
        
        $builds.value
    }
    END { }
}

