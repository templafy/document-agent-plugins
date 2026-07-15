# Templafy plugin (Claude)

Bundles the Templafy remote MCP server with skills for connecting to and using Templafy inside Claude.
Templafy turns a prompt into an on-brand, compliant PowerPoint built from your company's approved themes and
Document Agents.

## Skills

- **connect-verify-templafy** — set up and verify the Templafy connection (per-assistant OAuth, layered readiness) before creating documents.
- **create-branded-presentation** — turn any presentation request into a Templafy deck and keep it on Templafy's tools (the anti-hijack routing guard for ChatGPT).
- **discover-templafy** — browse the live Document Agents and themes and explain what Templafy offers.
- **troubleshoot-templafy-mcp** — diagnose Templafy failures (sign-in, no agents/themes, timeouts, widget not rendering).

## Packaging note

The `.claude-plugin/plugin.json` and `.mcp.json` wrapper is **Claude-only** — it bundles the connector + skills
for Claude Code. The `skills/` folders are portable `SKILL.md` and are the artifact reused for other assistants;
for ChatGPT distribution see `CHATGPT-DISTRIBUTION.md`.

## Install / test locally (Claude)

```bash
claude plugin validate ./templafy-plugin
claude --plugin-dir ./templafy-plugin
```

In-session, `/mcp` should list the `templafy` server, and the `connect-verify-templafy` skill should be
available. Using Templafy requires the tenant's Templafy MCP module enabled, OAuth sign-in, and network egress
to `*.templafy.com`.
