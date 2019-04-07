<#

.SYNOPSIS
This commend provides accesss Release Defintiions from Azure DevOps

.DESCRIPTION
The command will retrieve a full release definition (if it exists) 

.PARAMETER ProjectUrl
The full url for the Azure DevOps Project.  For example https://<organization>.visualstudio.com/<project> or https://dev.azure.com/<organization>/<project>

.PARAMETER Name
The name of the release definition to retrieve (use on this OR the id parameter)

.PARAMETER Id
The id of the release definition to retrieve (use on this OR the name parameter)

.PARAMETER ExpandFields
A common seperated list of fields to expand

.PARAMETER PAT
A valid personal access token with at least read access for release definitions

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Get-AzDoReleaseDefinition -ProjectUrl https://dev.azure.com/<organizztion>/<project> -Name <release defintiion name> -PAT <personal access token>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Get-AzDoReleaseDefinition()
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

        if ($Id -eq $null -and [string]::IsNullOrEmpty($Name)) { throw "Definition ID or Name must be specified";}

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "Parameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "$_ = '$($PSBoundParameters[$_])'" }

        $headers = Get-AzDoHttpHeader -PAT $PAT -ApiVersion $ApiVersion 

        $ProjectUrl = Get-AzDoRmUrlFromProjectUrl $ProjectUrl      
    }
    PROCESS
    {
        $apiParams = @()

        $apiParams += 

        if (-Not [string]::IsNullOrEmpty($ExpandFields)) 
        {
            $apiParams += "Expand=$($ExpandFields)"
        }

        if ($Id -ne $null -and $Id -ne 0) 
        {
            $apiUrl = Get-AzDoApiUrl -ProjectUrl $ProjectUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/release/definitions/$($Id)" -QueryStringParams $apiParams
        }
        else 
        {
            $apiParams += "searchText=$($Name)"

            $apiUrl = Get-AzDoApiUrl -ProjectUrl $ProjectUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/release/definitions" -QueryStringParams $apiParams
        }

        $releaseDefinitions = Invoke-RestMethod $apiUrl -Headers $headers 

        Write-Verbose "---------RELEASE DEFINITION---------"
        Write-Verbose $releaseDefinitions
        Write-Verbose "---------RELEASE DEFINITION---------"

        if ($releaseDefinitions.count -ne $null)
        {
            foreach($rd in $releaseDefinitions.value)
            {
                if ($rd.name -like $Name) {
                    Write-Verbose "Release Defintion Found $($rd.name) found."

                    $apiUrl = Get-AzDoApiUrl -ProjectUrl $ProjectUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/release/definitions/$($rd.id)" -QueryStringParams $apiParams
                    $releaseDefinitions = Invoke-RestMethod $apiUrl -Headers $headers 

                    return $releaseDefinitions
                }
            }
            Write-Verbose "Release definition $Name not found."
        } 
        elseif ($releaseDefinitions -ne $null) {
            return $releaseDefinitions
        }

        Write-Verbose "Release definition $Id not found."
        
        return $null
    }
    END { }
}

