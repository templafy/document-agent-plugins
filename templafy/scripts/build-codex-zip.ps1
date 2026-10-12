# Builds the public ChatGPT/Codex ZIP with .codex-plugin/plugin.json at the archive root.
# The MCP configuration and skills are shared with the Claude package.
# App references and lifecycle hooks are not accepted for public submission.

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem

$src = Split-Path -Parent $PSScriptRoot
$tempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
$stage = Join-Path $tempRoot ("templafy-codex-" + [guid]::NewGuid().ToString('N'))
$distDir = Join-Path $src "dist-codex"
$out = Join-Path $distDir "templafy-codex.zip"

try {
    New-Item -ItemType Directory -Force (Join-Path $stage ".codex-plugin") | Out-Null
    Copy-Item (Join-Path $src ".codex-plugin/plugin.json") (Join-Path $stage ".codex-plugin/plugin.json")
    Copy-Item (Join-Path $src ".mcp.json") (Join-Path $stage ".mcp.json")
    Copy-Item (Join-Path $src "assets") (Join-Path $stage "assets") -Recurse
    Copy-Item (Join-Path $src "skills") (Join-Path $stage "skills") -Recurse
    if (Test-Path (Join-Path $src "README.md")) {
        Copy-Item (Join-Path $src "README.md") (Join-Path $stage "README.md")
    }

    New-Item -ItemType Directory -Force $distDir | Out-Null
    [System.IO.Compression.ZipFile]::CreateFromDirectory($stage, "$stage.zip")
    Copy-Item -LiteralPath "$stage.zip" -Destination $out -Force

    Write-Host "Built $out"
    $zip = [System.IO.Compression.ZipFile]::OpenRead($out)
    try {
        $zip.Entries | ForEach-Object { $_.FullName } | Sort-Object | ForEach-Object { Write-Host "  $_" }
    }
    finally {
        $zip.Dispose()
    }
}
finally {
    $resolvedStage = [System.IO.Path]::GetFullPath($stage)
    if ([System.IO.Path]::GetDirectoryName($resolvedStage) -ne $tempRoot.TrimEnd('\', '/') -or
        -not ([System.IO.Path]::GetFileName($resolvedStage).StartsWith('templafy-codex-'))) {
        throw 'Refusing to remove a staging directory outside the expected temporary directory.'
    }
    if (Test-Path -LiteralPath "$resolvedStage.zip") { Remove-Item -LiteralPath "$resolvedStage.zip" -Force }
    if (Test-Path -LiteralPath $resolvedStage) {
        Remove-Item -LiteralPath $resolvedStage -Recurse -Force
    }
}
