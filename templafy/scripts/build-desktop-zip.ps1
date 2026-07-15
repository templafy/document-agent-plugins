# Builds the Claude Desktop / Cowork upload zip for the Templafy plugin.
#
# Desktop's "upload a custom plugin" picker only accepts a .zip (not .plugin — known bug),
# and expects the manifest at the archive ROOT (.claude-plugin/plugin.json), not inside a
# wrapping folder. It also treats the archive as a single plugin, so marketplace.json is
# deliberately excluded here (that file is only for the GitHub-repo marketplace path).
#
# Output: templafy-plugin/dist/templafy.zip  (gitignored)

$ErrorActionPreference = "Stop"
$src   = Split-Path -Parent $PSScriptRoot          # templafy-plugin/
$stage = Join-Path ([System.IO.Path]::GetTempPath()) ("templafy-pkg-" + (Get-Date -Format "yyyyMMddHHmmss"))
$out   = Join-Path $src "dist\templafy.zip"

try {
    New-Item -ItemType Directory -Force (Join-Path $stage ".claude-plugin") | Out-Null
    Copy-Item (Join-Path $src ".claude-plugin\plugin.json") (Join-Path $stage ".claude-plugin\plugin.json")
    Copy-Item (Join-Path $src ".mcp.json")                  (Join-Path $stage ".mcp.json")
    Copy-Item (Join-Path $src "skills")                     (Join-Path $stage "skills") -Recurse
    if (Test-Path (Join-Path $src "README.md")) { Copy-Item (Join-Path $src "README.md") (Join-Path $stage "README.md") }

    New-Item -ItemType Directory -Force (Join-Path $src "dist") | Out-Null
    Compress-Archive -Path (Get-ChildItem -Path $stage -Force | ForEach-Object FullName) -DestinationPath $out -Force

    Write-Host "Built $out"
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($out)
    $zip.Entries | ForEach-Object { $_.FullName } | Sort-Object | ForEach-Object { Write-Host "  $_" }
    $zip.Dispose()
}
finally {
    # Always remove the timestamped staging dir so repeated runs don't leave temp orphans.
    if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
}
