#requires -Version 7.4
<#
.SYNOPSIS
    Exports the local MCP contract and refreshes the sibling Integrations package's pinned tools.
.DESCRIPTION
    Use -Check to report differences without updating toolDescription.json.
    Exit codes: 0 = matching/updated; 1 = drift in check mode; 2 = invalid input/export failure.
#>
[CmdletBinding()]
param([switch]$Check)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
Set-StrictMode -Version Latest

$repositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../..'))
$importer = Join-Path (Split-Path -Parent $repositoryRoot) 'Integrations/TeamsApp/Update-CopilotTools.ps1'

try {
    if (-not (Test-Path -LiteralPath $importer -PathType Leaf)) {
        throw "Importer not found: $importer. Use sibling IntegrationManagement and Integrations checkouts containing the export/import scripts."
    }

    Push-Location -LiteralPath $repositoryRoot
    try {
        & dotnet run --project WebApi.Mcp -c Release -- --export-tools
        if ($LASTEXITCODE -ne 0) { exit 2 }

        # The importer calls exit, so run it in its own PowerShell process.
        $powerShell = Join-Path $PSHOME $(if ($IsWindows) { 'pwsh.exe' } else { 'pwsh' })
        $importArguments = @('-NoProfile', '-File', $importer)
        if ($Check) { $importArguments += '-Check' }
        & $powerShell @importArguments
        exit $LASTEXITCODE
    } finally {
        Pop-Location
    }
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 2
}
