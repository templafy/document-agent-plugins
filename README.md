# Templafy Document Agent Plugins

Install the Templafy plugin into Claude, ChatGPT, or Codex to create on-brand,
brand-compliant presentations through Templafy's Document Agents and approved themes —
straight from a chat prompt.

The plugin lives in [`templafy/`](./templafy); the repo root is the marketplace catalog.

## Install

### ChatGPT

Plugins → **+** → **Import from GitHub**, then point it at the **plugin folder** — not the
repo root (the root is a marketplace catalog, not a single plugin):

```
https://github.com/templafy/document-agent-plugins/tree/main/templafy
```

### Codex CLI

```
codex plugin marketplace add templafy/document-agent-plugins
```

### Claude Code

```
/plugin marketplace add templafy/document-agent-plugins
/plugin install templafy
```

### Claude Desktop

Settings → Customize → Plugins → add this marketplace, then install **Templafy Plugin**.

## What's included

The `templafy` plugin bundles the Templafy MCP connector (`https://mcp.templafy.com/`) and
skills that route presentation requests to Templafy and keep generation on-brand:

- **create-branded-presentation** — build a deck through Templafy end-to-end.
- **connect-verify-templafy** — connect and verify the Templafy connector.
- **discover-templafy** — browse available Document Agents and themes.
- **troubleshoot-templafy-mcp** — diagnose connector issues.

See [`templafy/CHATGPT-DISTRIBUTION.md`](./templafy/CHATGPT-DISTRIBUTION.md) for ChatGPT/Codex
specifics.

---

_This repository is a read-only mirror generated from Templafy's internal monorepo. File issues
here; code changes are made upstream._
