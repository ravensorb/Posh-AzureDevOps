<#

.SYNOPSIS
This command retrieve Identiies from Azure DevOps (used for picker lookup)

.DESCRIPTION
The command will retrieve Azure DevOps identiies (if they exists) 

.PARAMETER AzDoConnect
A valid AzDoConnection object

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.PARAMETER QueryString
What to search for

.EXAMPLE
Get-AzDoIdentities -QueryString <search string>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Get-AzDoIdentities()
{
    [CmdletBinding(
        DefaultParameterSetName="Id"
    )]
    param
    (
        # Common Parameters
        [PoshAzDo.AzDoConnectObject][parameter(ValueFromPipelinebyPropertyName = $true, ValueFromPipeline = $true)]$AzDoConnection,
        [string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [string][parameter()]$QueryString
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

        if (-Not $ApiVersion.Contains("preview")) { $ApiVersion = "5.0-preview.1" }
        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0-preview.1"}

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

        # https://dev.azure.com/{organization}/_apis/IdentityPicker/Identities
        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.OrganizationUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/IdentityPicker/Identities" -QueryStringParams $apiParams

        # {
        #     "query": "Shawn",
        #     "identityTypes": ["group", "user"],
        #     "operationScopes": ["ims", "source"],
        #     "options": {
        #         "MinResults": 5,
        #         "MaxResults": 20
        #     },
        #     "properties": ["DisplayName", "IsMru", "ScopeName", "SamAccountName", "Active", "SubjectDescriptor", "Department", "JobTitle", "Mail", "MailNickname", "PhysicalDeliveryOfficeName", "SignInAddress", "Surname", "Guest", "TelephoneNumber", "Manager", "Description"]
        # }

        $query = @{
            query=$queryString;
            identityTypes=@("group","user");
            operationScopes=@("ims","source");
            options=@{
                MinResults=5;
                MaxResults=20;
            };
            properties=@("DisplayName", "IsMru", "ScopeName", "SamAccountName", "Active", "SubjectDescriptor", "Department", "JobTitle", "Mail", "MailNickname", "PhysicalDeliveryOfficeName", "SignInAddress", "Surname", "Guest", "TelephoneNumber", "Manager", "Description")
        }

        $body = $query | ConvertTo-Json -Depth 10 -Compress

        Write-Verbose $body

        $results = Invoke-RestMethod $apiUrl -Method POST -Body $body -ContentType 'application/json' -Headers $AzDoConnection.HttpHeaders
        
        Write-Verbose "---------RESULTS---------"
        Write-Verbose $results
        Write-Verbose "---------RESULTS---------"

        if ($null -ne $results)
        {
            return $results.results.identities
        }

        Write-Verbose "No identities found"
}
    END { }
}

