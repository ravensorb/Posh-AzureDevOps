<#

.SYNOPSIS
This command retrieve Users from Azure DevOps

.DESCRIPTION
The command will retrieve Azure DevOps users (if they exists) 

.PARAMETER AzDoConnect
A valid AzDoConnection object

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.PARAMETER UserName
The name of the the user to retreive

.PARAMETER UserEmail
The email of the user to retrieve

.PARAMETER UserId
The userid of the user to retrieve
.EXAMPLE
Get-AzDoUsers

.EXAMPLE
Get-AzDoUsers -UserEmail <user email address>

.EXAMPLE
Get-AzDoUsers -UserName <user name>

.EXAMPLE
Get-AzDoUsers -UserId <user id>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Get-AzDoUsers()
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
        [parameter(Mandatory=$false, ParameterSetName="Name")][Alias("name")][string]$UserName,
        [parameter(Mandatory=$false, ParameterSetName="Email")][Alias("email")][string]$UserEmail,
        [parameter(Mandatory=$false, ParameterSetName="Id")][Alias("id")][Guid]$UserId = [Guid]::Empty
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

        # https://vssps.dev.azure.com/{organization}/_apis/graph/users?api-version=5.0-preview.1
        $apiUrl = Get-AzDoApiUrl -RootPath $($AzDoConnection.VsspUrl) -ApiVersion $ApiVersion -BaseApiPath "/_apis/graph/users" -QueryStringParams $apiParams

        $users = Invoke-RestMethod $apiUrl -Headers $AzDoConnection.HttpHeaders
        
        Write-Verbose "---------USERS---------"
        Write-Verbose ($users| ConvertTo-Json -Depth 50 | Out-String)
        Write-Verbose "---------USERS---------"

        if ($null -ne $users.count)
        {   
            Write-Verbose "User Count: $($users.count)"

            if (-Not [string]::IsNullOrEmpty($UserName) -or $UserId -ne [Guid]::Empty -or -Not [string]::IsNullOrEmpty($UserEmail))
            {
                foreach($item in $users.value)
                {
                    Write-Verbose "User: $($item.cuid) - $($item.displayName) - $($item.mailAddress)"

                    if ($item.displayName -like $UserName -or $item.origanId -eq $UserId -or ($item.mailAddress -eq $UserEmail -and -Not [string]::IsNullOrEmpty($UserEmail))) {
                        Write-Verbose "User Found $($item.displayName) found."

                        return $item
                    }                     
                }
            }
            else {
                return $users.value
            }
        } 

        Write-Verbose "No Users found."

        return $null
    }
    END 
    { 
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}

