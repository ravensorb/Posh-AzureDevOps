function Add-AzDoLibraryVariable()
{
    [CmdletBinding()]
    param
    (
        [string][parameter(Mandatory = $true)]$ProjectUrl,
        [string][parameter(Mandatory = $true)]$VariableGroupName,
        [string]$VariableGroupDescription,
        [string][parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][Alias("name")]$VariableName,
        [string][parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][Alias("value")]$VariableValue,
        [bool][parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]$Secret,
        [string]$PAT,
        [switch]$Reset,
        [switch]$Force,
        [string]$ApiVersion = $global:AzDoApiVersion
    )
    BEGIN
    {
        if (-not $PSBoundParameters.ContainsKey('Verbose'))
        {
            $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
        }        
    
        if (-Not (Test-Path variable:ApiVersion)) { $ApiVersion = "5.0-preview.1"}

        # Write-Host "Importing Variable into Azure DevOps Variable Groups" -ForegroundColor Green
        # Write-Host "`tProject: $ProjectUrl" -ForegroundColor Green
        # Write-Host "`tVariable Group: $VariableGroupName" -ForegroundColor Green
        # Write-Host "`tVariable: $VariableName = $VariableValue" -ForegroundColor Green
        # Write-Host "`tIs Variable a Secret: $Secret" -ForegroundColor Green
        # Write-Host "`tCreate Variable Group If doesn't Exists: $Force" -ForegroundColor Green
        # Write-Host "`tClear Variable Group before importing: $Reset" -ForegroundColor Green

        Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
        Write-Verbose "Parameter Values"

        $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "$_ = '$($PSBoundParameters[$_])'" }

        $headers = Get-AzDoHttpHeader -PAT $PAT -ApiVersion $ApiVersion

        $method = "Post"
        $variableGroup = Get-AzDoLibraryVariableGroup $ProjectUrl $VariableGroupName -PAT $PAT -ApiVersion $ApiVersion

        if($variableGroup)
        {
            Write-Verbose "Variable group $VariableGroupName exists."

            if ($Reset)
            {
                Write-Verbose "Reset = $Reset : remove all variables."
                foreach($prop in $variableGroup.variables.PSObject.Properties.Where{$_.MemberType -eq "NoteProperty"})
                {
                    $variableGroup.variables.PSObject.Properties.Remove($prop.Name)
                }
            }

            $id = $variableGroup.id
            $apiUrl = Get-AzDoApiUrl -ProjectUrl $ProjectUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/distributedtask/variablegroups/$($id)"
            $method = "Put"
        }
        else
        {
            Write-Verbose "Variable group $VariableGroupName not found."
            if ($Force)
            {
                Write-Verbose "Create variable group $VariableGroupName."
                $variableGroup = @{name=$VariableGroupName;description=$VariableGroupDescription;variables=New-Object PSObject;}
                $apiUrl = Get-AzDoApiUrl -ProjectUrl $ProjectUrl -ApiVersion $ApiVersion -BaseApiPath "/_apis/distributedtask/variablegroups"
            }
            else
            {
                throw "Cannot add variable to nonexisting variable group $VariableGroupName; use the -Force switch to create the variable group."
            }
        }
    }
    PROCESS
    {
        Write-Verbose "Adding $VariableName with value $VariableValue..."
        $variableGroup.variables | Add-Member -Name $VariableName -MemberType NoteProperty -Value @{value=$VariableValue;isSecret=$Secret} -Force
    }
    END
    {
        Write-Verbose "Persist variable group $VariableGroupName."
        $body = $variableGroup | ConvertTo-Json -Depth 10 -Compress
        Write-Verbose $body
        $response = Invoke-RestMethod $apiUrl -Method $method -Body $body -ContentType 'application/json' -Header $headers
        
        Write-Verbose "Response: $($response.id)"

        #return $response.id        
    }
}
