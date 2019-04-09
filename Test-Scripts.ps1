[CmdletBinding()]
param
(
    [string]$ProjectUrl = $global:AzDoTestProjectUrl,

    [string]$RepoName = $global:AzDoTestRepoName,

    [string]$BuildDefinitionName = $global:AzDoTestBuildDefinitionName,
    [string]$BuildVariableName = $global:AzDoTestBuildVariableName,
    [string]$BuildVariableValue = $global:AzDoTestBuildVariableValue,

    [string]$ReleaseDefinitionName = $global:AzDoTestReleaseDefinitionName,
    [string]$ReleaseVariableName = $global:AzDoTestReleaseVariableName,
    [string]$ReleaseVariableValue = $global:AzDoTestReleaseVariableValue,

    [string]$LibraryVariableGroupName = $global:AzDoTestLibraryVariableGroupName,
    [string]$LibraryVariableName = $global:AzDoTestLibraryVariableName,
    [string]$LibraryVariableValue = $global:AzDoTestLibraryVariableValue,

    [string][parameter(Mandatory = $true, ValueFromPipelinebyPropertyName = $true)]$PAT = $global:AzDoTestPAT,
    [string]$ApiVersion = $global:AzDoApiVersion
)
BEGIN
{
    Write-Verbose "Entering script $($MyInvocation.MyCommand.Name)"
    Write-Verbose "Parameter Values"
    $PSBoundParameters.Keys | ForEach-Object { Write-Verbose "$_ = '$($PSBoundParameters[$_])'" }
}
PROCESS
{
    if ([string]::IsNullOrEmpty($ProjectUrl)) { throw "Project Url is Required"}

    if ([string]::IsNullOrEmpty($RepoName)) { throw "RepoName is Required"}

    if ([string]::IsNullOrEmpty($BuildDefinitionName)) { throw "BuildDefinitionName is Required"}
    if ([string]::IsNullOrEmpty($BuildVariableName)) { throw "BuildVariableName is Required"}
    if ([string]::IsNullOrEmpty($BuildVariableValue)) { throw "BuildVariableValue is Required"}

    if ([string]::IsNullOrEmpty($ReleaseDefinitionName)) { throw "ReleaseDefinitionName is Required"}
    if ([string]::IsNullOrEmpty($ReleaseVariableName)) { throw "ReleaseVariableName is Required"}
    if ([string]::IsNullOrEmpty($ReleaseVariableValue)) { throw "ReleaseVariableValue is Required"}

    if ([string]::IsNullOrEmpty($LibraryVariableGroupName)) { throw "LibraryVariableGroupName is Required"}
    if ([string]::IsNullOrEmpty($LibraryVariableName)) { throw "LibraryVariableName is Required"}
    if ([string]::IsNullOrEmpty($LibraryVariableValue)) { throw "LibraryVariableValue is Required"}

    ##################################################################################################################
    ##################################################################################################################
    Write-Host "Testing Build API Calls" -ForegroundColor Green
    ##################################################################################################################

    Write-Host "`tGet Build Definition By Name: " -NoNewline
    $buildDefinitionTestResult = Get-AzDoBuildDefinition -ProjectUrl $ProjectUrl -PAT $PAT -ApiVersion $ApiVersion -BuildDefinitionName $BuildDefinitionName
    if ($buildDefinitionTestResult -ne $null) { Write-Host "`tSuccess" -ForegroundColor Green } else { Write-Host "`tFailed" -ForegroundColor Red }
    Write-Host "`tGet Build Definition By Id: " -NoNewline
    $buildDefinitionTestResult = Get-AzDoBuildDefinition -ProjectUrl $ProjectUrl -PAT $PAT -ApiVersion $ApiVersion -BuildDefinitionId $buildDefinitionTestResult.id
    if ($buildDefinitionTestResult -ne $null) { Write-Host "`tSuccess" -ForegroundColor Green } else { Write-Host "`tFailed" -ForegroundColor Red }

    Write-Host "`tGet Build Pipeline Variables: " -NoNewline
    $buildVaraibleTestResult = Get-AzDoBuildPipelineVariables -ProjectUrl $ProjectUrl -PAT $PAT -ApiVersion $ApiVersion -BuildDefinitionName $BuildDefinitionName 
    if ($buildVaraibleTestResult -ne $null) { Write-Host "`tSuccess" -ForegroundColor Green } else { Write-Host "`tFailed" -ForegroundColor Red }

    Write-Host "`tAdd Build Pipeline Variable: " -NoNewline
    $buildAddVaraibleTestResult = Add-AzDoBuildPipelineVariable -ProjectUrl $ProjectUrl -PAT $PAT -ApiVersion $ApiVersion -BuildDefinitionName $BuildDefinitionName -VariableName $BuildVariableName -VariableValue $([DateTime]::Now.ToString())
    if ($buildAddVaraibleTestResult -ne $null) { Write-Host "`tSuccess" -ForegroundColor Green } else { Write-Host "`tFailed" -ForegroundColor Red }

    Write-Host "`tRemove Build Pipeline Variable: " -NoNewline
    $buildRemoveVaraibleTestResult = Remove-AzDoBuildPipelineVariable -ProjectUrl $ProjectUrl -PAT $PAT -ApiVersion $ApiVersion -BuildDefinitionName $BuildDefinitionName -VariableName $BuildVariableName
    if ($buildRemoveVaraibleTestResult -ne $null) { Write-Host "`tSuccess" -ForegroundColor Green } else { Write-Host "`tFailed" -ForegroundColor Red }

    ##################################################################################################################
    ##################################################################################################################
    Write-Host "Testing Library API Calls" -ForegroundColor Green
    ##################################################################################################################

    Write-Host "`tAdd Library Group: " -NoNewline
    $libraryVariableGroupRestResult = New-AzDoLibraryVariableGroup -ProjectUrl $ProjectUrl -PAT $PAT -ApiVersion $ApiVersion -VariableGroupName $LibraryVariableGroupName 
    if ($libraryVariableGroupRestResult -ne $null) { Write-Host "`tSuccess" -ForegroundColor Green } else { Write-Host "`tFailed" -ForegroundColor Red }

    Write-Host "`tAdd Library Variable: " -NoNewline
    $libraryVariableGroupRestResult = Add-AzDoLibraryVariable -ProjectUrl $ProjectUrl -PAT $PAT -ApiVersion $ApiVersion -VariableGroupName $LibraryVariableGroupName -VariableName $LibraryVariableName -VariableValue $LibraryVariableValue
    if ($libraryVariableGroupRestResult -ne $null) { Write-Host "`tSuccess" -ForegroundColor Green } else { Write-Host "`tFailed" -ForegroundColor Red }

    Write-Host "`tGet Library Variable Group: " -NoNewline
    $libraryVariableGroupRestResult = Get-AzDoLibraryVariableGroup -ProjectUrl $ProjectUrl -PAT $PAT -ApiVersion $ApiVersion -VariableGroupName $LibraryVariableGroupName
    if ($libraryVariableGroupRestResult -ne $null) { Write-Host "`tSuccess" -ForegroundColor Green } else { Write-Host "`tFailed" -ForegroundColor Red }

    Write-Host "`tRemove Library Variable: " -NoNewline
    $libraryVariableGroupRestResult = Remove-AzDoLibraryVariable -ProjectUrl $ProjectUrl -PAT $PAT -ApiVersion $ApiVersion -VariableGroupName $LibraryVariableGroupName -VariableName $LibraryVariableName
    if ($libraryVariableGroupRestResult -ne $null) { Write-Host "`tSuccess" -ForegroundColor Green } else { Write-Host "`tFailed" -ForegroundColor Red }

    #Write-Host "`tImport Library Variable: " -NoNewline
    #$libraryVariableGroupImportRestResult = Import-AzDoLibraryVariables -ProjectUrl $ProjectUrl -PAT $PAT -ApiVersion $ApiVersion -VariableGroupName $LibraryVariableGroupName
    #if ($libraryVariableGroupImportRestResult -ne $null) { Write-Host "`tSuccess" -ForegroundColor Green } else { Write-Host "`tFailed" -ForegroundColor Red }

    Write-Host "`tRemove Library Group: " -NoNewline
    $libraryVariableGroupRestResult = Remove-AzDoLibraryVariableGroup -ProjectUrl $ProjectUrl -PAT $PAT -ApiVersion $ApiVersion -VariableGroupName $LibraryVariableGroupName 
    if ($libraryVariableGroupRestResult -ne $null) { Write-Host "`tSuccess" -ForegroundColor Green } else { Write-Host "`tFailed" -ForegroundColor Red }

    ##################################################################################################################
    ##################################################################################################################
    Write-Host "Testing Release API Calls" -ForegroundColor Green
    ##################################################################################################################

    Write-Host "`tGet Release Definition By Name: " -NoNewline
    $releaseDefinitionTestResult = Get-AzDoReleaseDefinition -ProjectUrl $ProjectUrl -PAT $PAT -ApiVersion $ApiVersion -ReleaseDefinitionName $ReleaseDefinitionName
    if ($releaseDefinitionTestResult -ne $null) { Write-Host "`tSuccess" -ForegroundColor Green } else { Write-Host "`tFailed" -ForegroundColor Red }
    Write-Host "`tGet Release Definition By ID: " -NoNewline
    $releaseDefinitionTestResult = Get-AzDoReleaseDefinition -ProjectUrl $ProjectUrl -PAT $PAT -ApiVersion $ApiVersion -ReleaseDefinitionId $releaseDefinitionTestResult.id
    if ($releaseDefinitionTestResult -ne $null) { Write-Host "`tSuccess" -ForegroundColor Green } else { Write-Host "`tFailed" -ForegroundColor Red }

    Write-Host "`tAdd Release Variable: " -NoNewline
    $releaseVaraibleTestResult = Add-AzDoReleasePipelineVariable -ProjectUrl $ProjectUrl -PAT $PAT -ApiVersion $ApiVersion -ReleaseDefinitionName $ReleaseDefinitionName -VariableName $ReleaseVariableName -VariableValue $ReleaseVariableValue
    if ($releaseVaraibleTestResult -ne $null) { Write-Host "`tSuccess" -ForegroundColor Green } else { Write-Host "`tFailed" -ForegroundColor Red }

    Write-Host "`tGet Release Variable: " -NoNewline
    $releaseVaraibleTestResult = Get-AzDoReleasePipelineVariables -ProjectUrl $ProjectUrl -PAT $PAT -ApiVersion $ApiVersion -ReleaseDefinitionName $ReleaseDefinitionName
    if ($releaseVaraibleTestResult -ne $null) { Write-Host "`tSuccess" -ForegroundColor Green } else { Write-Host "`tFailed" -ForegroundColor Red }

    Write-Host "`tRemove Release Variable: " -NoNewline
    $releaseVaraibleTestResult = Remove-AzDoReleasePipelineVariable -ProjectUrl $ProjectUrl -PAT $PAT -ApiVersion $ApiVersion -ReleaseDefinitionName $ReleaseDefinitionName -VariableName $ReleaseVariableName
    if ($releaseVaraibleTestResult -ne $null) { Write-Host "`tSuccess" -ForegroundColor Green } else { Write-Host "`tFailed" -ForegroundColor Red }

    ##################################################################################################################
    ##################################################################################################################
    Write-Host "Testing Repo API Calls" -ForegroundColor Green
    ##################################################################################################################
    Write-Host "`tGet Repo Branches: " -NoNewline
    $repoTestResult = Get-AzDoRepoBranches -ProjectUrl $ProjectUrl -PAT $PAT -ApiVersion $ApiVersion -Name $RepoName
    if ($repoTestResult -ne $null) { Write-Host "`tSuccess" -ForegroundColor Green } else { Write-Host "`tFailed" -ForegroundColor Red }

}
END { }
