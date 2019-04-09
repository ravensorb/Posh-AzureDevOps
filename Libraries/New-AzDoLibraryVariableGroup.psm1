<#

.SYNOPSIS
Create a new Library Variable Group

.DESCRIPTION
The command will create a new library variable group

.PARAMETER ProjectUrl
The full url for the Azure DevOps Project.  For example https://<organization>.visualstudio.com/<project> or https://dev.azure.com/<organization>/<project>

.PARAMETER VariableGroupName
The name of the variable group to retrieve

.PARAMETER Description
A description for this library group

.PARAMETER PAT
A valid personal access token with at least read access for build definitions

.PARAMETER ApiVersion
Allows for specifying a specific version of the api to use (default is 5.0)

.EXAMPLE
New-AzDoLibraryVariableGroup -ProjectUrl https://dev.azure.com/<organizztion>/<project> -VariableGroupName <variable group name> -PAT <personal access token>

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function New-AzDoLibraryVariableGroup()
{
    [CmdletBinding()]
    param
    (
        [string][parameter(Mandatory = $true, ValueFromPipelinebyPropertyName = $true)]$ProjectUrl,
        [string][parameter(Mandatory = $true, ValueFromPipelinebyPropertyName = $true)]$VariableGroupName,
        [string]$Description,
        [string][parameter(Mandatory = $true, ValueFromPipelinebyPropertyName = $true)]$PAT,
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

        $variableGroup = Get-AzDoLibraryVariableGroup -ProjectUrl $ProjectUrl -VariableGroupName $VariableGroupName -PAT $PAT

        if ($variableGroup) 
        {
            Write-Verbose "Variable group $VariableGroupName exists"

            return $variableGroup
        }

        Write-Verbose "Variable group $VariableGroupName not found."

        Write-Verbose "Create variable group $VariableGroupName."

        $variableGroup = @{name=$VariableGroupName;description=$Description;variables=New-Object PSObject;}
        $apiUrl = Get-AzDoApiUrl -ProjectUrl $ProjectUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/distributedtask/variablegroups"

        $variableGroup.variables | Add-Member -Name "NewVariable1" -MemberType NoteProperty -Value @{value="";isSecret=$false} -Force

        #Write-Verbose "Persist variable group $VariableGroupName."
        $body = $variableGroup | ConvertTo-Json -Depth 10 -Compress
        
        #Write-Verbose $body
        $response = Invoke-RestMethod $apiUrl -Method $method -Body $body -ContentType 'application/json' -Header $headers    

        Write-Verbose "Response: $($response.id)"

        $response
    }
    END
    {
        Write-Verbose "Leaving script $($MyInvocation.MyCommand.Name)"
    }
}
