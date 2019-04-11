$scriptName = split-path -leaf $MyInvocation.MyCommand.Definition
$rootPath = split-path -parent $MyInvocation.MyCommand.Definition
$assemblies = gci -re "$rootPath\bin" -in *.dll 
$scripts = gci -re "$rootPath\modules" -in *.psm1 | ?{ $_.Name -ne $scriptName }

Write-Host "Loading all assemblies in $rootPath" -ForegroundColor Green
foreach ( $item in $assemblies ) {
    Write-Host "`tLoading $($item.Name)" -ForegroundColor Yellow
    Import-Module $item.FullName -Force
}

Write-Host "Loading all modules in $rootPath" -ForegroundColor Green
foreach ( $item in $scripts ) {
    Write-Host "`tLoading $($item.Name)" -ForegroundColor Yellow
    Import-Module -Name $item.FullName -Force
}

Write-Host "Setting Azure DevOps Global variables" -ForegroundColor Green
Set-AzDoGlobalVariables