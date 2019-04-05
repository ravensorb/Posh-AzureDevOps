[CmdletBinding()]
param
(
    [string][parameter(Mandatory = $true)]$ProjectUrl,
    [string][parameter(Mandatory = $true)]$RepoName,
    [string][parameter(Mandatory = $true)]$BuildDefinitionName,
    [string][parameter(Mandatory = $true)]$BuildVariableName,
    [string][parameter(Mandatory = $true)]$ReleaseDefinitionName,
    [string][parameter(Mandatory = $true)]$ReleaseVariableName,
    [string][parameter(Mandatory = $true)]$LibraryVariableGroupName,
    [string][parameter(Mandatory = $true)]$PAT,
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
    ##################################################################################################################
    Write-Host "Testing Build API Calls" -ForegroundColor Green
    Write-Host "`tGet Build Definition: " -NoNewline
    $buildDefinitionTestResult = Get-AzDoBuildDefinition -ProjectUrl $ProjectUrl -PAT $PAT -ApiVersion $ApiVersion -Name $BuildDefinitionName
    if ($buildDefinitionTestResult -ne $null) { Write-Host "`tSuccess" -ForegroundColor Green } else { Write-Host "`tFailed" -ForegroundColor Red }

    Write-Host "`tGet Build Pipeline Variable: " -NoNewline
    $buildVaraibleTestResult = Get-AzDoBuildPipelineVariables -ProjectUrl $ProjectUrl -PAT $PAT -ApiVersion $ApiVersion -DefinitionName $BuildDefinitionName -VariableName $BuildVariableName
    if ($buildVaraibleTestResult -ne $null) { Write-Host "`tSuccess" -ForegroundColor Green } else { Write-Host "`tFailed" -ForegroundColor Red }

    ##################################################################################################################
    Write-Host "Testing Library API Calls" -ForegroundColor Green
    Write-Host "`tGet Library Variable Group: " -NoNewline
    $libraryVariableGroupRestResult = Get-AzDoLibraryVariableGroup -ProjectUrl $ProjectUrl -PAT $PAT -ApiVersion $ApiVersion -Name $LibraryVariableGroupName
    if ($libraryVariableGroupRestResult -ne $null) { Write-Host "`tSuccess" -ForegroundColor Green } else { Write-Host "`tFailed" -ForegroundColor Red }

    ##################################################################################################################
    Write-Host "Testing Release API Calls" -ForegroundColor Green
    Write-Host "`tGet Release Definition: " -NoNewline
    $releaseDefinitionTestResult = Get-AzDoRmReleaseDefinition -ProjectUrl $ProjectUrl -PAT $PAT -ApiVersion $ApiVersion -Name $ReleaseDefinitionName
    if ($releaseDefinitionTestResult -ne $null) { Write-Host "`tSuccess" -ForegroundColor Green } else { Write-Host "`tFailed" -ForegroundColor Red }

    Write-Host "`tGet Build Release Variable: " -NoNewline
    $releaseVaraibleTestResult = Get-AzDoRmPipelineVariables -ProjectUrl $ProjectUrl -PAT $PAT -ApiVersion $ApiVersion -DefinitionName $ReleaseDefinitionName -VariableName $ReleaseVariableName
    if ($releaseVaraibleTestResult -ne $null) { Write-Host "`tSuccess" -ForegroundColor Green } else { Write-Host "`tFailed" -ForegroundColor Red }

    ##################################################################################################################
    Write-Host "Testing Repo API Calls" -ForegroundColor Green
    Write-Host "`tGet Repo Branches: " -NoNewline
    $repoTestResult = Get-AzDoRepoBranches -ProjectUrl $ProjectUrl -PAT $PAT -ApiVersion $ApiVersion -Name $RepoName
    if ($repoTestResult -ne $null) { Write-Host "`tSuccess" -ForegroundColor Green } else { Write-Host "`tFailed" -ForegroundColor Red }

}
END { }
