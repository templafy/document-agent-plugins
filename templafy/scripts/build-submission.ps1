# Prepares the Templafy plugin submission artifact and checks submission-readiness.
#
# Builds the DEFAULT plugin (the FULL plugin: skills + the .mcp.json MCP connector, WITHOUT the
# .app.json app-id reference), then validates the produced zip's manifest and connector and prints
# the manual submission checklist. This does not upload anything.
#
# Portal: platform.openai.com/plugins  (submission type: With MCP)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root = Split-Path -Parent $PSScriptRoot
$zipPath = Join-Path $root "dist-codex\templafy-codex.zip"

Write-Host "== Building submission artifact (full plugin, no app-id reference) =="
& (Join-Path $PSScriptRoot "build-codex-zip.ps1")

Write-Host ""
Write-Host "== Validating the produced artifact =="

$zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
try {
    function Read-Entry($name) {
        $e = $zip.Entries | Where-Object { $_.FullName -eq $name }
        if (-not $e) { return $null }
        $sr = New-Object System.IO.StreamReader($e.Open())
        try { return $sr.ReadToEnd() } finally { $sr.Close() }
    }
    $names = $zip.Entries | ForEach-Object { $_.FullName }
    $manifestText = Read-Entry ".codex-plugin/plugin.json"
    $mcpText      = Read-Entry ".mcp.json"
    $hasApp       = $names -contains ".app.json"
    $skillCount   = ($names | Where-Object { $_ -match '/SKILL\.md$' }).Count
}
finally { $zip.Dispose() }

$problems = @()

if (-not $manifestText) { $problems += "manifest .codex-plugin/plugin.json missing from zip" }
else {
    $m = $manifestText | ConvertFrom-Json
    foreach ($f in "name","version","description","skills","mcpServers") {
        if (-not $m.$f) { $problems += "manifest missing top-level: $f" }
    }
    $iface = $m.interface
    if (-not $iface) { $problems += "manifest missing interface block" }
    else {
        foreach ($f in "displayName","shortDescription","longDescription","category","websiteURL","developerName") {
            if (-not $iface.$f) { $problems += "manifest missing interface.$f" }
        }
        if (-not $iface.defaultPrompt -or @($iface.defaultPrompt).Count -lt 1) { $problems += "interface.defaultPrompt is empty" }
    }
    if ($m.PSObject.Properties.Name -contains 'apps') { $problems += "manifest still has 'apps' (app-id reference) — expected absent for the MCP-only submission" }
}

if (-not $mcpText) { $problems += ".mcp.json (MCP connector) missing from zip" }
else {
    $mcp = $mcpText | ConvertFrom-Json
    $url = $mcp.mcpServers.templafy.url
    if ($url -notmatch '^https://') { $problems += ".mcp.json templafy url is not https ($url)" }
    else { Write-Host "  MCP connector: $url" }
}
Write-Host "  Skills bundled: $skillCount"
Write-Host "  App-id reference in zip: $hasApp  (expected: False)"

if ($problems.Count) {
    Write-Host ""
    Write-Host "MANIFEST/ARTIFACT ISSUES:"
    $problems | ForEach-Object { Write-Host "  - $_" }
} else {
    Write-Host "  Artifact validation: OK"
}

Write-Host ""
Write-Host "== Manual submission checklist (portal inputs this script cannot generate) =="
@(
    "Assets: icon, logo, screenshots",
    "brandColor",
    "Privacy policy URL + Terms URL",
    "Domain verification token at https://<domain>/.well-known/openai-apps-challenge",
    "5 positive + 3 negative test cases (see REGRESSION-TESTS.md Part B)",
    "Confirm the .mcp.json connector triggers Templafy OAuth sign-in on a real install"
) | ForEach-Object { Write-Host "  [ ] $_" }

Write-Host ""
Write-Host "Artifact: $zipPath"

if ($problems.Count) {
    Write-Host ""
    Write-Host "Submission-readiness FAILED: $($problems.Count) issue(s) above."
    exit 1
}
