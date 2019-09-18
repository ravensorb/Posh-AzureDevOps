<#

.SYNOPSIS
Retrieve the work items related to  the specified release 

.DESCRIPTION
The command will retrieve the work items associated with the specified release 

.PARAMETER ReleaseId
The id of the release to retrieve (use on this OR the name parameter)

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Get-AzDoReleaseWorkItems -ProjectUrl https://dev.azure.com/<organizztion>/<project> -ReleaseId <release id> -PAT <personal access token>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Get-AzDoReleaseWorkItems()
{
    [CmdletBinding(
        DefaultParameterSetName='ID'
    )]
    param
    (
        # Common Parameters
        [PoshAzDo.AzDoConnectObject][parameter(ValueFromPipelinebyPropertyName = $true, ValueFromPipeline = $true)]$AzDoConnection,
        [string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [int][parameter(ParameterSetName='ID', ValueFromPipelinebyPropertyName = $true)]$ReleaseId,
        [int]$Count = 1
    )
    BEGIN
    {
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }        
    
        if (-Not $ApiVersion.Contains("preview")) { $ApiVersion = "5.0-preview.1" }
        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0-preview.1"}

        if (-Not (Test-Path varaible:$AzDoConnection) -or $AzDoConnection -eq $null)
        {
            $AzDoConnection = Get-AzDoActiveConnection

            if ($AzDoConnection -eq $null) { throw "AzDoConnection or ProjectUrl must be valid" }
        }

        if ($ReleaseId -eq $null -and $build -eq $null) { throw "Build ID or Build object must be specified"; }

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "`tParameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "`t`t$_ = '$($PSBoundParameters[$_])'" }        
    }
    PROCESS
    {
        $apiParams = @()

        #$apiParams += "`$top=$($Count)"

        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.ReleaseManagementUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/Release/releases/$($ReleaseId)/workitems" -QueryStringParams $apiParams

        $buildWorkItems = Invoke-RestMethod $apiUrl -Headers $AzDoConnection.HttpHeaders

        Write-Verbose "---------RELEASE WORKITEMS---------"
        Write-Verbose $buildWorkItems
        Write-Verbose "---------RELEASE WORKITEMS---------"

        #Write-Verbose "Build status $($build.id) not found."
        if (-Not $buildWorkItems -or $buildWorkItems.count -eq 0) {
            Write-Verbose "No Workitems Found Related to release $ReleaseId"

            return $null
        }

        foreach ($wit in $buildWorkItems.value) {
            Write-Verbose "`t$($wit.id) => $($wit.url)"

            $witDetails = Invoke-RestMethod $wit.url -Headers $AzDoConnection.HttpHeaders | Select-Object -ExpandProperty fields

            $witCustom = [pscustomobject]@{
                Id = $wit.id;
                Url = $wit.url;
                Details = $witDetails;
            }

            $witCustom | Select-Object Id, Url -ExpandProperty Details
        }

    }
    END { }
}

