# Templafy plugin

Bundles the Templafy remote MCP server with skills for connecting to and using Templafy in ChatGPT, Codex, and Claude.
Templafy turns a prompt into an on-brand, compliant PowerPoint or Word document built from your company's
approved themes, Document Agents and Word template.

## Skills

- **connect-verify-templafy** — set up and verify the Templafy connection (per-assistant OAuth, layered readiness) before creating documents.
- **create-branded-presentation** — turn any presentation request into a Templafy deck and keep it on Templafy's tools (the anti-hijack routing guard for ChatGPT).
- **create-branded-word-document** — turn a Word document request into a branded `.docx`: what stays literal, how to write a ```brief that survives expansion, and how to send a document too long for one call.
- **discover-templafy** — browse the live Document Agents and themes and explain what Templafy offers.
- **troubleshoot-templafy-mcp** — diagnose Templafy failures (sign-in, no agents/themes, timeouts, widget not rendering).

## Packaging note

Claude uses `.claude-plugin/plugin.json`; ChatGPT and Codex use `.codex-plugin/plugin.json`.
Both share `.mcp.json` and `skills/`. Build the public ChatGPT/Codex ZIP with
`scripts/build-codex-zip.ps1`; it includes the listing assets and remote MCP configuration.
For submission steps, see `CHATGPT-DISTRIBUTION.md` in the source repository.

## Install / test locally (Claude)

```bash
claude plugin validate ./templafy-plugin
claude --plugin-dir ./templafy-plugin
```

In-session, `/mcp` should list the `templafy` server, and the `connect-verify-templafy` skill should be
available. Using Templafy requires the tenant's Templafy MCP module enabled, OAuth sign-in, and network egress
to `*.templafy.com`.
