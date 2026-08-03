# Builds the ChatGPT/Codex plugin upload zip for the Templafy plugin.
#
# A Codex plugin is normally a folder (installed into ~/.codex/plugins/ or referenced from a
# marketplace.json), but a zip is the convenient artifact for uploading/sharing. The manifest
# must sit at the archive ROOT (.codex-plugin/plugin.json), so the zip contains the plugin's
# contents at the top level — not wrapped in a folder.
#
# Included (the ChatGPT/Codex side of the dual-manifest plugin):
#   .codex-plugin/plugin.json   plugin manifest (targets ./.mcp.json)
#   .mcp.json                   remote Templafy connector, shared with Claude
#   skills/                     shared SKILL.md + references/ + per-skill agents/openai.yaml
#   README.md                   (if present)
#
# ChatGPT requires the connector config to be the ROOT ".mcp.json" ("mcpServers must resolve to
# the root .mcp.json"). The one shared .mcp.json — { "mcpServers": { "templafy": { "type": "http",
# "url": ... } } } — is accepted by both Claude and Codex/ChatGPT (confirmed via upload), so it
# ships as-is; there is no Codex-specific connector file.
#
# Deliberately excluded:
#   .claude-plugin/             Claude plugin manifest (Codex reads .codex-plugin/ instead; .mcp.json
#                               is shared and kept)
#   .agents/plugins/…           the marketplace catalog (references plugins; not part of one plugin)
#   scripts/, dist*/, docs      build/QA/mirror tooling and internal docs
#
# Output: templafy-plugin/dist-codex/templafy-codex.zip  (gitignored)

param(
    # Bundle the pre-registered Templafy app-id reference (.app.json -> asdk_app id).
    # OFF by default. The default build is the FULL plugin — skills + the .mcp.json MCP connector —
    # with ONLY the environment-specific app-id reference removed. This default is used for BOTH
    # submission and testing. -IncludeApp re-attaches the registered app id if a build ever needs it.
    [switch]$IncludeApp
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem

$src     = Split-Path -Parent $PSScriptRoot          # templafy-plugin/
$stage   = Join-Path ([System.IO.Path]::GetTempPath()) ("templafy-codex-" + (Get-Date -Format "yyyyMMddHHmmss"))
$distDir = Join-Path $src "dist-codex"
$out     = Join-Path $distDir "templafy-codex.zip"

try {
    New-Item -ItemType Directory -Force (Join-Path $stage ".codex-plugin") | Out-Null

    # The .mcp.json MCP connector is kept in EVERY build (below) — this is a full plugin, not a
    # skills-only wrapper. Only the app-id reference (.app.json -> pre-registered app id) is
    # CONDITIONAL: excluded by default (both submission and testing); pass -IncludeApp to re-attach it.
    # Add/remove the app-id reference via a JSON round-trip so the manifest stays valid regardless of
    # key order (a raw line-strip could leave a dangling trailing comma if "apps" were ever last).
    $manifest = Get-Content (Join-Path $src ".codex-plugin\plugin.json") -Raw | ConvertFrom-Json
    if ($IncludeApp) {
        if (-not (Test-Path (Join-Path $src ".app.json"))) { throw "-IncludeApp set but .app.json not found" }
        if ($manifest.PSObject.Properties.Name -notcontains 'apps') {
            $manifest | Add-Member -NotePropertyName apps -NotePropertyValue "./.app.json"
        }
        Copy-Item (Join-Path $src ".app.json") (Join-Path $stage ".app.json")
        Write-Host "App-id reference INCLUDED (.app.json bundled)"
    } else {
        if ($manifest.PSObject.Properties.Name -contains 'apps') { $manifest.PSObject.Properties.Remove('apps') }
        Write-Host "App-id reference EXCLUDED (default) — full plugin with the .mcp.json MCP connector, no app-id"
    }
    ($manifest | ConvertTo-Json -Depth 20) | Set-Content -Path (Join-Path $stage ".codex-plugin\plugin.json") -Encoding utf8

    # Connector: the shared .mcp.json is accepted by both Claude and Codex/ChatGPT — ship as-is.
    Copy-Item (Join-Path $src ".mcp.json") (Join-Path $stage ".mcp.json")

    Copy-Item (Join-Path $src "skills") (Join-Path $stage "skills") -Recurse
    if (Test-Path (Join-Path $src "README.md")) { Copy-Item (Join-Path $src "README.md") (Join-Path $stage "README.md") }

    New-Item -ItemType Directory -Force $distDir | Out-Null
    if (Test-Path $out) { Remove-Item -Force $out }
    # CreateFromDirectory places the staged CONTENTS at the archive root using forward slashes.
    [System.IO.Compression.ZipFile]::CreateFromDirectory($stage, $out)

    Write-Host "Built $out"
    $zip = [System.IO.Compression.ZipFile]::OpenRead($out)
    $zip.Entries | ForEach-Object { $_.FullName } | Sort-Object | ForEach-Object { Write-Host "  $_" }
    $zip.Dispose()
}
finally {
    if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
}
