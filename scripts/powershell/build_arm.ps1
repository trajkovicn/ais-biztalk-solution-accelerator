# Build ARM template artifact for the Deploy-to-Azure button
# Requires Bicep CLI installed.

$ErrorActionPreference = 'Stop'

Write-Host "Compiling Bicep -> ARM (azuredeploy.json)" -ForegroundColor Cyan
bicep build ./infra/bicep/main.bicep --outfile ./infra/arm/azuredeploy.json
Write-Host "Done: ./infra/arm/azuredeploy.json" -ForegroundColor Green
