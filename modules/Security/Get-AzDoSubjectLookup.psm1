<#

.SYNOPSIS
This command provides retrieve Users from Azure DevOps

.DESCRIPTION
The command will retrieve Azure DevOps users (if they exists) 

.PARAMETER AzDoConnect
A valid AzDoConnection object

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.PARAMETER SubjectName
The name of the the user to retreive

.EXAMPLE
Get-AzDoSubjectLookup -Subject

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Get-AzDoSujectLookup()
{
    [CmdletBinding(
        DefaultParameterSetName="Id"
    )]
    param
    (
        # Common Parameters
        [parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelinebyPropertyName=$true)][PoshAzDo.AzDoConnectObject]$AzDoConnection,
        [parameter(Mandatory=$false)][string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [parameter(Mandatory=$false, ParameterSetName="Id")][Alias("id")][string]$Subject
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

        if (-Not $ApiVersion.Contains("preview")) { $ApiVersion = "5.1-preview.1" }
        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.1-preview.1"}

        if (-Not (Test-Path varaible:$AzDoConnection) -and $AzDoConnection -eq $null)
        {
            $AzDoConnection = Get-AzDoActiveConnection

            if ($null -eq $AzDoConnection) { Write-Error -ErrorAction $errorPreference -Message "AzDoConnection or ProjectUrl must be valid" }
        }

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "`tParameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "`t`t$_ = '$($PSBoundParameters[$_])'" }        
    }
    PROCESS
    {
        $apiParams = @()

        # https://vssps.dev.azure.com/{organization}/_apis/graph/subjectlookup?api-version=5.1-preview.1 
        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.VsspUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/graph/subjectlookup" -QueryStringParams $apiParams

        $body = "{ 'lookupKeys': [{ 'descriptor': '$($Subject)'}]}" 

        $results = Invoke-RestMethod $apiUrl -Method POST -Body $body -ContentType 'application/json' -Headers $AzDoConnection.HttpHeaders
        
        Write-Verbose "---------RESULTS---------"
        Write-Verbose ($results| ConvertTo-Json -Depth 50 | Out-String)
        Write-Verbose "---------RESULTS---------"

        if ($null -ne $results)
        {
            $results.value.PSObject.Properties | foreach-object {
                $_.value
            }
        }
    }
    END 
    { 
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}

