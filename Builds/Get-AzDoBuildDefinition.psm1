    <#

.SYNOPSIS
This commend provides accesss Build Defintiions from Azure DevOps

.DESCRIPTION
The command will retrieve a full build definition (if it exists) 

.PARAMETER ProjectUrl
The full url for the Azure DevOps Project.  For example https://<organization>.visualstudio.com/<project> or https://dev.azure.com/<organization>/<project>

.PARAMETER Name
The name of the build definition to retrieve (use on this OR the id parameter)

.PARAMETER Id
The id of the build definition to retrieve (use on this OR the name parameter)

.PARAMETER ExpandFields
A common seperated list of fields to expand

.PARAMETER PAT
A valid personal access token with at least read access for build definitions

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Get-AzDoBuildDefinition -ProjectUrl https://dev.azure.com/<organizztion>/<project> -Name <build defintiion name> -PAT <personal access token>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Get-AzDoBuildDefinition()
{
    [CmdletBinding(
        DefaultParameterSetName='Name'
    )]
    param
    (
        [string][parameter(Mandatory = $true)]$ProjectUrl,
        [string][parameter(ParameterSetName='Name')]$Name,
        [int][parameter(ParameterSetName='ID')]$Id,
        [string]$ExpandFields,
        [string][parameter(Mandatory = $true)]$PAT,
        [string]$ApiVersion = $global:AzDoApiVersion
    )
    BEGIN
    {
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }        
    
        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0"}
        if ($Id -eq $null -and [string]::IsNullOrEmpty($Name)) { throw "Definition ID or Name must be specified"; }

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "`tParameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "`t`t$_ = '$($PSBoundParameters[$_])'" }

        $headers = Get-AzDoHttpHeader -PAT $PAT -ApiVersion $ApiVersion
    }
    PROCESS
    {
        $apiUrl = Get-AzDoApiUrl -ProjectUrl $ProjectUrl -BaseApiPath "/_apis/build/definitions"

        $apiParams = @()

        if (-Not [string]::IsNullOrEmpty($ExpandFields)) 
        {
            $apiParams += "Expand=$($ExpandFields)"
        }

        if ($Id -ne $null -and $Id -ne 0) 
        {
            $apiUrl = Get-AzDoApiUrl -ProjectUrl $ProjectUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/build/definitions/$($Id)" -QueryStringParams $apiParams
        }
        else 
        {
            $apiParams += "searchText=$($Name)"

            $apiUrl = Get-AzDoApiUrl -ProjectUrl $ProjectUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/build/definitions" -QueryStringParams $apiParams
        }

        $buildDefinitions = Invoke-RestMethod $apiUrl -Headers $headers
        
        Write-Verbose "---------BUILD DEFINITION---------"
        Write-Verbose $buildDefinitions
        Write-Verbose "---------BUILD DEFINITION---------"

        Write-Verbose "Build Definition: $($buildDefinitions)"

        if ($buildDefinitions.count -ne $null)
        {   
            foreach($bd in $buildDefinitions.value)
            {
                if ($bd.name -like $Name){
                    Write-Verbose "Release Defintion Found $($bd.name) found."

                    $apiUrl = Get-AzDoApiUrl -ProjectUrl $ProjectUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/build/definitions/$($bd.id)" -QueryStringParams $apiParams
                    $buildDefinitions = Invoke-RestMethod $apiUrl -Headers $headers

                    return $buildDefinitions
                }
            }
            Write-Verbose "Build definition $Name not found."
        } 
        elseif ($buildDefinitions -ne $null) {
            return $buildDefinitions
        }

        Write-Verbose "Build definition $Id not found."
        
        return $null
    }
    END { }
}

