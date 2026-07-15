# Connecting Templafy, per assistant

Templafy is a remote MCP server: `https://mcp.templafy.com/`. Every client requests the scopes `library.read`
and `library.generate`, and signs in via OAuth. The exact flow differs per assistant.

## Claude Code / Claude Desktop / claude.ai

Add the remote MCP server by URL (`https://mcp.templafy.com/`) and complete the browser sign-in when prompted.
Claude registers itself dynamically — no client secret to paste. Approve the `library.read` / `library.generate`
scopes; you're returned to Claude after consent.

## ChatGPT

Templafy connects as a ChatGPT connector/app. Add or enable the Templafy connector, then complete the OAuth
sign-in popup; ChatGPT returns to its connector callback after consent. In managed workspaces, an admin may need
to enable the connector first.

## Microsoft 365 Copilot

Templafy is enabled as an agent/connector by a Microsoft 365 administrator. Sign-in uses your Microsoft identity
and returns through the Microsoft consent redirect. If Templafy doesn't appear, ask your M365 admin to enable
it.

## Perplexity

Add Templafy as an MCP connection by URL and complete the OAuth sign-in; Perplexity returns to its connection
callback after consent.

## Every connection needs

- The tenant's Templafy MCP module enabled.
- A successful OAuth sign-in (steps above).
- Network egress to `*.templafy.com`.

If any of these is missing, the Templafy tools won't appear or will return sign-in errors — hand off to
`troubleshoot-templafy-mcp`.
