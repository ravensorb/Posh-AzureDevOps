<#

.SYNOPSIS
Retrieve the work items related to  the specified build 

.DESCRIPTION
The command will retrieve the work items associated with the specified build 

.PARAMETER BuildId
The id of the build to retrieve (use on this OR the name parameter)

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
Get-AzDoBuildWorkItems -BuildId <build id>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Get-AzDoBuildWorkItems()
{
    [CmdletBinding(
        DefaultParameterSetName='ID'
    )]
    param
    (
        # Common Parameters
        [parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelinebyPropertyName=$true)][PoshAzDo.AzDoConnectObject]$AzDoConnection,
        [parameter(Mandatory=$false)][string]$ApiVersion = $global:AzDoApiVersion,

        # Module Parameters
        [parameter(Mandatory=$true, ParameterSetName="ID", ValueFromPipelinebyPropertyName=$true)][int]$BuildId,
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

        if ($BuildId -eq $null) { Write-Error -ErrorAction $errorPreference -Message "Build ID must be specified"; }

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "`tParameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "`t`t$_ = '$($PSBoundParameters[$_])'" }        
    }
    PROCESS
    {
        $apiParams = @()

        $apiParams += "`$top=$($Count)"

        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.ProjectUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/build/builds/$($BuildId)/workitems" -QueryStringParams $apiParams

        $buildWorkItems = Invoke-RestMethod $apiUrl -Headers $AzDoConnection.HttpHeaders

        Write-Verbose "---------BUILD WORKITEMS---------"
        Write-Verbose ($buildWorkItems| ConvertTo-Json -Depth 50 | Out-String)
        Write-Verbose "---------BUILD WORKITEMS---------"

        #Write-Verbose "Build status $($build.id) not found."
        if (-Not $buildWorkItems -or $buildWorkItems.count -eq 0) {
            Write-Verbose "No Workitems Found Related to build $BuildId"

            return $null
        }

        foreach ($wit in $buildWorkItems.value) {
            Write-Verbose "`t$($wit.id) => $($wit.url)"

            $witDetails = Invoke-RestMethod $wit.url -Headers $AzDoConnection.HttpHeaders | Select-Object -ExpandProperty fields

            Write-Verbose "---------WORK ITEM---------"
            Write-Verbose ($witDetails| ConvertTo-Json -Depth 50 | Out-String)
            Write-Verbose "---------WORK ITEM---------"
    
            $witCustom = [pscustomobject]@{
                Id = $wit.id;
                Url = $wit.url;
                Details = $witDetails;
            }

            $witCustom | Select-Object Id, Url -ExpandProperty Details
        }

    }
    END 
    { 
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}

