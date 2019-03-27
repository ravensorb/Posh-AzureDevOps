$scriptName = split-path -leaf $MyInvocation.MyCommand.Definition
$rootPath = split-path -parent $MyInvocation.MyCommand.Definition
$scripts = gci -re $rootPath -in *.psm1 | ?{ $_.Name -ne $scriptName }

Write-Host "Loading all modules in $rootPath" -ForegroundColor Green
foreach ( $item in $scripts ) {
    Write-Host "`tLoading $($item.Name)" -ForegroundColor Yellow
    Import-Module -Name $item.FullName -Force
}