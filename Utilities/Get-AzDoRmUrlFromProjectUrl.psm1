<#

.SYNOPSIS
Convert a standard Azure DevOps Project URL into an Azure DevOps Release Manager URL

.DESCRIPTION
The command will return a Azure DevOps url for access the release management APIs based on the Project URL specified

.PARAMETER ProjectUrl
The full url for the Azure DevOps Project.  For example https://<organization>.visualstudio.com/<project> or https://dev.azure.com/<organization>/<project>

.EXAMPLE
Get-AzDoRmUrlFromProjectUrl -ProjectUrl https://dev.azure.com/<organizztion>/<project> 

.NOTES

.LINK
https://github.com/ravensorb/Posh-AzureDevOps

#>
function Get-AzDoRmUrlFromProjectUrl()
{
    [CmdletBinding()]
    param
    (
        [string][parameter(Mandatory = $true, ValueFromPipelinebyPropertyName = $true)]$ProjectUrl
    )
    BEGIN
    {
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }        

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "Parameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "$_ = '$($PSBoundParameters[$_])'" }
    }
    PROCESS
    {
        $ProjectUrl = $ProjectUrl.TrimEnd("/")

        if (-Not $ProjectUrl.Contains("vsrm."))
        {
            #Write-Verbose "Updating Project URL"
            if ($ProjectUrl.Contains(".visualstudio.com"))
            {
                #Write-Verbose "Setting Visual Studio Version"
                $ProjectUrl = $ProjectUrl.Replace(".visualstudio.com", ".vsrm.visualstudio.com")
            }
            elseif ($ProjectUrl.Contains("dev.azure.com"))
            {
                #Write-Verbose "Setting Azure Version"
                $ProjectUrl = $ProjectUrl.Replace("dev.azure.com", "vsrm.dev.azure.com")
            }
            else 
            {
                # Looks like this is invalid so lets return a null result
                $ProjectUrl = $null
            }
        }

        $ProjectUrl
    }
    END { }    
}