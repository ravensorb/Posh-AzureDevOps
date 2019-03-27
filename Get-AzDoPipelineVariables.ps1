function Get-AzDoPipelineVariables()
{
    [CmdletBinding()]
    param
    (
        [string][parameter(Mandatory = $true)]$ProjectUrl,
        [int][parameter(Mandatory = $true)]$DefinitionId,
        [string][parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][Alias("name")]$VariableName,
        [string][parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][Alias("env")]$EnvironmentName = $null,
        [string]$PAT
    )
    BEGIN   
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
                Write-Error "Unsupported URL: $ProjectUrl"    

                Exit
            }
        }

        if ([string]::IsNullOrEmpty($EnvironmentName)) { $EnvironmentName = "*" }

        Write-Host "Importing Variable into Azure DevOps Variable Groups" -ForegroundColor Green
        Write-Host "`tProject: $ProjectUrl" -ForegroundColor Green
        Write-Host "`tDefinition ID: $DefinitionId" -ForegroundColor Green
        Write-Host "`tVariable: $VariableName = $VariableValue" -ForegroundColor Green
        Write-Host "`tEnvironment: $EnvironmentName" -ForegroundColor Green

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "Parameter Values"

        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "$_ = '$($PSBoundParameters[$_])'" }

        $headers = Get-HttpHeader -PAT $PAT 
    }
    PROCESS
    {
        $url = "$($ProjectUrl)/_apis/release/definitions/$($DefinitionId)?expand=Environments?api-version=3.0-preview"
        $definition = Invoke-RestMethod $url -Headers $headers

        $variables = @()

        if (-Not [string]::IsNullorEmpty($EnvironmentName)) 
        {
            Write-Verbose "Getting ariables for Environment $EnvironmentName"
            foreach($environment in $definition.environments)
            {
                if ($enviroEnvironmentNamenment -eq "*" -or $environment -like "*$EnvironmentName*") {
                    $environment.variables.PSObject.Properties | ? { $_.MemberType -eq "NoteProperty"} | % { 
                        Write-Verbose $_.Value
                        $variables += [pscustomobject]@{
                            Name = $_.Name;
                            Value = $_.Value.value;
                            Environment = $environment.Name;
                        }
                    }
                }
            }
        }

        $variables += $definition.variables.PSObject.Properties | ? { $_.MemberType -eq "NoteProperty"} | % { 
            $variables += [pscustomobject]@{
                Name = $_.Name;
                Value = $_.Value;
                Environment = "Release";
            }
        };

        $variables
    }
    END
    {

    }
}

function Get-HttpHeader()
{
    [CmdletBinding()]
    param
    (
        [string]$PAT
    )
    BEGIN 
    {
        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "Parameter Values"
        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "$_ = '$($PSBoundParameters[$_])'" }
    }
    PROCESS
    {
        $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        # Base64-encodes the Personal Access Token (PAT) appropriately
        if (-Not [string]::IsNullOrEmpty($PAT)) {
            Write-Verbose "Creating HTTP Auth Header for PAT"
            $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes((":$PAT")))
            Write-Verbose $base64AuthInfo
            $headers.Add("Authorization", ("Basic {0}" -f $base64AuthInfo))
        }
        $headers.Add("Accept", "application/json;api-version=3.2-preview.1")
    
        Write-Verbose $headers

        return $headers   
    }
    END
    {

    }
}
