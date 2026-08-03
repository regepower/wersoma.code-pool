Param([ValidateSet('win-x64','win-arm64','win-x86')] [string]$rid = 'win-x64')
Write-Host "Restore..."
dotnet restore
if ($LASTEXITCODE -ne 0) { Write-Error "restore failed"; exit 1 }
Write-Host "Publish self-contained $rid..."
dotnet publish -c Release -r $rid --self-contained true -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -p:PublishTrimmed=false
if ($LASTEXITCODE -ne 0) { Write-Error "publish failed"; exit 1 }
Write-Host "Done. exe at bin\Release\net8.0-windows\$rid\publish\QrWedge.exe"
