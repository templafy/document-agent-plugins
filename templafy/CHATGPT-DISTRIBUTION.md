# Distributing Templafy to ChatGPT and Codex

The public package uses `.codex-plugin/plugin.json`, a supported compatibility format.
Maintain listing metadata here in source: edits made only in the dashboard or `dist-codex/`
will not survive the next build.

## Build

From the repository root:

```powershell
./WebApi.Mcp/plugins/templafy/scripts/build-codex-zip.ps1
```

The output is `dist-codex/templafy-codex.zip`, with these entries at its root:

- `.codex-plugin/plugin.json`
- `.mcp.json` — the remote endpoint, shared with Claude
- `assets/templafy-light.png` and `assets/templafy-dark.png` — the supplied theme variants, used for both listing and composer
- `skills/` — all five skills, references, and `agents/openai.yaml` files
- `README.md`

The build excludes the Claude manifest, marketplace catalogs, and internal tooling.
Public submissions do not accept app references or lifecycle hooks. Configure authentication
for the declared MCP endpoint in the dashboard.

## Update the existing listing

Upload the ZIP through the existing Templafy plugin's **Upload plugin to make changes** action.
The package version comes from `.codex-plugin/plugin.json`; downloaded drafts are comparison snapshots.
The Codex package name must remain `app-6a2ab750d2788191ba2f32a602fabe29` to match the existing listing. The user-facing display name is `Templafy`.

The manifest includes the listing text, three starter prompts, all four listing URLs, and icon paths.
The privacy link points directly to the general privacy policy. Dark icons, brand colors, and
screenshots are optional.

Confirm any saved dashboard review materials: the demo recording, five positive and three
negative cases, release notes, reviewer access, domain verification, and current MCP scan.
Never put private reviewer credentials in the ZIP. Review fields omitted from the package preserve
saved dashboard values. Complete the applicable checks and attestations before submitting;
publish the new version after approval.

See [package guidance](https://developers.openai.com/plugins/build/plugins),
[submission and metadata](https://developers.openai.com/plugins/deploy/submission), and
[submission errors](https://developers.openai.com/plugins/deploy/submission-errors).

## Verify behavior and review the skills

Run `REGRESSION-TESTS.md` against an authenticated installation and inspect the tool trace.
Exercise both presentation and Word generation, including error handling and client rendering.
Package validation alone does not verify OAuth or document generation.

The current presentation and Word skills contain broad instructions to prefer Templafy over built-in
skills and tools. Review those instructions and their `references/chatgpt-routing.md` files against
OpenAI's fair-play and user-intent requirements before submission. A Templafy workflow should honor
an explicit choice of another tool and platform safeguards. Do not disable competing tools to make
a routing test pass. Review the existing routing-focused regression expectations on the same basis.

See the [plugin guidelines](https://developers.openai.com/plugins/plugin-guidelines).
