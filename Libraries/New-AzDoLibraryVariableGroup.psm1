<#

.SYNOPSIS
Get all variables in a specific Azure DevOps libary

.DESCRIPTION
The  command will retreive all variables to the specificed library

.PARAMETER ProjectUrl
The full url for the Azure DevOps Project.  For example https://<organization>.visualstudio.com/<project> or https://dev.azure.com/<organization>/<project>

.PARAMETER Name
The name of the variable group to retrieve

.PARAMETER PAT
A valid personal access token with at least read access for build definitions

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
New-AzDoLibraryVariableGroup -ProjectUrl https://dev.azure.com/<organizztion>/<project> -Name <variable group name> -PAT <personal access token>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function New-AzDoLibraryVariableGroup()
{
    [CmdletBinding()]
    param
    (
        [string][parameter(Mandatory = $true)]$ProjectUrl,
        [string][parameter(Mandatory = $true)]$Name,
        [string]$Description,
        [string]$PAT,
        [string]$ApiVersion = $global:AzDoApiVersion
    )
    BEGIN
    {
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }        
    
        if (-Not $ApiVersion.Contains("preview")) { $ApiVersion = "5.0-preview.1" }
        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0-preview.1"}

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "Parameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "$_ = '$($PSBoundParameters[$_])'" }

        $headers = Get-AzDoHttpHeader -PAT $PAT -ApiVersion $ApiVersion
    }
    PROCESS
    {
        $method = "Post"

        $variableGroup = Get-AzDoLibraryVariableGroup -ProjectUrl $ProjectUrl -Name $Name -PAT $PAT -ApiVersion $ApiVersion

        if ($variableGroup) 
        {
            Write-Verbose "Variable group $Name exists"

            return $variableGroup
        }

        Write-Verbose "Variable group $Name not found."

        Write-Verbose "Create variable group $Name."

        $variableGroup = @{name=$Name;description=$Description;variables=New-Object PSObject;}
        $apiUrl = Get-AzDoApiUrl -ProjectUrl $ProjectUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/distributedtask/variablegroups"

        $variableGroup.variables | Add-Member -Name "NewVariable1" -MemberType NoteProperty -Value @{value="";isSecret=$false} -Force

        #Write-Verbose "Persist variable group $Name."
        $body = $variableGroup | ConvertTo-Json -Depth 10 -Compress
        
        #Write-Verbose $body
        $response = Invoke-RestMethod $apiUrl -Method $method -Body $body -ContentType 'application/json' -Header $headers    
    }
    END
    {
        Write-Verbose "Response: $($response.id)"

        $response
    }
}
