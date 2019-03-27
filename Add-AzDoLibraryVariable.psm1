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
        [switch]$Force
    )
    BEGIN
    {
       if (-Not (Test-Path variable:global:AzDoApiVersion)) { $global:AzDoApiVersion = "5.0"}

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
        $method = "Post"
        $variableGroup = Get-VariableGroup $ProjectUrl $VariableGroupName -PAT $PAT

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
            $restApi = "$($ProjectUrl)/_apis/distributedtask/variablegroups/$id"
            $method = "Put"
        }
        else
        {
            Write-Verbose "Variable group $VariableGroupName not found."
            if ($Force)
            {
                Write-Verbose "Create variable group $VariableGroupName."
                $variableGroup = @{name=$VariableGroupName;description=$VariableGroupDescription;variables=New-Object PSObject;}
                $restApi = "$($ProjectUrl)/_apis/distributedtask/variablegroups?api-version=$($global:AzDoApiVersion)"
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
        $headers = Get-AzDoHttpHeader -pat $PAT 

        Write-Verbose "Persist variable group $VariableGroupName."
        $body = $variableGroup | ConvertTo-Json -Depth 10 -Compress
        Write-Verbose $body
        $response = Invoke-RestMethod $restApi -Method $method -Body $body -ContentType 'application/json' -Header $headers
        
        #return $response.id        
    }
}

function Get-VariableGroup()
{
    [CmdletBinding()]
    param
    (
        [string][parameter(Mandatory = $true)]$ProjectUrl,
        [string][parameter(Mandatory = $true)]$Name,
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
        $headers = Get-AzDoHttpHeader -PAT $PAT 

        $ProjectUrl = $ProjectUrl.TrimEnd("/")
        $url = "$($ProjectUrl)/_apis/distributedtask/variablegroups"
        $variableGroups = Invoke-RestMethod $url -Headers $headers 
        
        Write-Verbose $variableGroups

        foreach($variableGroup in $variableGroups.value){
            if ($variableGroup.name -like $Name){
                Write-Verbose "Variable group $Name found."
                return $variableGroup
            }
        }
        Write-Verbose "Variable group $Name not found."
        return $null
    }
    END { }
}
