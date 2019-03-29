function Add-AzDoRmPipelineVariable()
{
    [CmdletBinding()]
    param
    (
        [string][parameter(Mandatory = $true)]$ProjectUrl,
        [string][parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][Alias("name")]$VariableName,
        [string][parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][Alias("value")]$VariableValue,
        [string][parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][Alias("env")]$EnvironmentName,
        [bool][parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]$Secret,
        [int[]]$VariableGroups,
        [int][parameter(Mandatory = $true)]$DefinitionId,
        [string]$PAT,
        [string]$Comment,
        [switch]$Reset,
        [string]$ApiVersion = $global:AzDoApiVersion
    )
    BEGIN
    {
       if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0"}

        $headers = Get-AzDoHttpHeader $PAT 

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "Parameter Values"
        $PSBoundParameters.Keys | ForEach-Object { if ($Secret -and $_ -eq "VariableValue") { Write-Verbose "VariableValue = *******" } else { Write-Verbose "$_ = '$($PSBoundParameters[$_])'" }}

        $ProjectUrl = $ProjectUrl.TrimEnd("/")

        $url = "$($ProjectUrl)/_apis/release/definitions/$($DefinitionId)?expand=Environments?api-version=$($ApiVersion)"
        $definition = Invoke-RestMethod $url -Headers $headers

        if ($Reset)
        {
            foreach($environment in $definition.environments)
            {
                foreach($prop in $environment.variables.PSObject.Properties.Where{$_.MemberType -eq "NoteProperty"})
                {
                    $environment.variables.PSObject.Properties.Remove($prop.Name)
                }
            }

            foreach($prop in $definition.variables.PSObject.Properties.Where{$_.MemberType -eq "NoteProperty"})
            {
                $definition.variables.PSObject.Properties.Remove($prop.Name)
            }

            $definition.variableGroups = @()
        }
    }
    PROCESS
    {
        $value = @{value=$VariableValue}
    
        if ($Secret)
        {
            $value.Add("isSecret", $true)
        }

        if ($EnvironmentName)
        {
            $environment = $definition.environments.Where{$_.name -like $EnvironmentName}

            if($environment)
            {
                $environment.variables | Add-Member -Name $VariableName -MemberType NoteProperty -Value $value -Force
            }
            else
            {
                Write-Warning "Environment '$($environment.name)' not found in the given release"
            }
        }
        else
        {
            $definition.variables | Add-Member -Name $VariableName -MemberType NoteProperty -Value $value -Force
        }
    }
    END
    {
        $definition.source = "restApi"

        if ($Comment)
        {
            $definition | Add-Member -Name "comment" -MemberType NoteProperty -Value $Comment
        }
        
        if ($VariableGroups)
        {
            foreach($variable in $VariableGroups)
            {
                if ($definition.variableGroups -notcontains $variable)
                {
                    $definition.variableGroups += $variable
                }
            }
        }

        $body = $definition | ConvertTo-Json -Depth 10 -Compress

        Invoke-RestMethod "$($ProjectUrl)/_apis/release/definitions?api-version=$($ApiVersion)" -Method Put -Body $body -ContentType 'application/json' -Headers $headers | Out-Null
    }
}

