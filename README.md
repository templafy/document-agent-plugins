# Templafy Document Agent Plugins

Install the Templafy plugin into Claude Code or Claude Desktop to create on-brand,
brand-compliant presentations through Templafy's Document Agents and approved themes —
straight from a chat prompt.

## Install (Claude Code)

```
/plugin marketplace add templafy/document-agent-plugins
/plugin install templafy
```

## Install (Claude Desktop)

Settings → Customize → Plugins → add this marketplace, then install **templafy**.

## What's included

The `templafy` plugin bundles the Templafy MCP connector (`https://mcp.templafy.com/`) and
skills that route presentation requests to Templafy and keep generation on-brand:

- **create-branded-presentation** — build a deck through Templafy end-to-end.
- **connect-verify-templafy** — connect and verify the Templafy connector.
- **discover-templafy** — browse available Document Agents and themes.
- **troubleshoot-templafy-mcp** — diagnose connector issues.

See [`templafy/`](./templafy) for the plugin and
[`templafy/CHATGPT-DISTRIBUTION.md`](./templafy/CHATGPT-DISTRIBUTION.md) for using the skills
with ChatGPT.

---

_This repository is a read-only mirror generated from Templafy's internal monorepo. File issues
here; code changes are made upstream._
