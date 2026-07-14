# Distributing Templafy to ChatGPT (Codex plugin)

ChatGPT now consumes the **Codex plugin format** — the same `templafy-plugin/` folder, via its
`.codex-plugin/plugin.json` manifest. It reaches **ChatGPT Work (web)** and **Codex (desktop app)**.
This supersedes the old "zip the skill folders" approach (removed).

Activation is still the real bottleneck: when a skill is active it fixes the routing failure, but
ChatGPT's built-in slide/artifact route can win *before* the skill is selected. So distribution has
two parts — **ship the plugin** and **configure the agent so Templafy wins routing**.

## 1. What ChatGPT uses in this plugin

The ChatGPT/Codex side of the dual-manifest plugin:

```
WebApi.Mcp/plugins/templafy/
├── .codex-plugin/plugin.json     # Codex manifest (name, version, skills, mcpServers, interface)
├── skills/<name>/
│   ├── SKILL.md                  # the workflow (shared with Claude)
│   └── agents/openai.yaml        # Codex metadata: MCP dependency + allow_implicit_invocation
└── .mcp.json                     # remote Templafy connector (shared with Claude)
```

The `.claude-plugin/` files and `.mcp.json` are **Claude-only** — Codex ignores them. There is **no
zip step**; the plugin is a folder.

## 2. Install / distribute

- **Local / dev testing** — copy the plugin folder into `~/.codex/plugins/` (personal) or a repo's
  `plugins/` directory, or add a `marketplace.json` entry whose `source.path` points at the plugin.
- **Public** — submit through the portal at `platform.openai.com/plugins` (submission type: *With
  MCP*). This needs assets (icon / logo / screenshots), a `brandColor`, privacy/terms URLs, domain
  verification (a token at `/.well-known/openai-apps-challenge`), and 5 positive + 3 negative test
  cases. Fill the `interface` block in `.codex-plugin/plugin.json` accordingly.

> **Connector auth:** `.mcp.json` declares the hosted Templafy connector by URL. Confirm on a
> real install that it triggers the Templafy OAuth sign-in. If it doesn't, ship a **skills-only**
> plugin (drop the `mcpServers` pointer) and rely on the already-published Templafy ChatGPT app to
> provide the connector; each skill's `agents/openai.yaml` still declares the dependency.

## 3. Configure the agent so Templafy wins routing (the durable fix)

A skill description raises selection odds but can't guarantee beating ChatGPT's native artifact
route. At the agent/workspace level:

1. **Disable / deprioritize the competing built-ins** for the Templafy agent — Canvas, image
   generation, and especially the built-in **slide/presentation/artifact generator**. If ChatGPT
   can't make slides itself, it can't intercept.
2. **Scope the agent to Templafy** so "make a deck" maps to the connector.
3. Add a **top-level agent instruction** (above the skill): *"All presentation / deck / PowerPoint
   requests must use the Templafy connector; never use built-in slide, artifact, or canvas
   generation."* A top-level instruction intercepts earlier than a skill body.
4. Keep **`create-branded-presentation`** (the routing guard) prominent, and its
   `references/chatgpt-routing.md` available. Each skill's `agents/openai.yaml` sets
   `allow_implicit_invocation: true` so the skills can fire without an explicit call.

## 4. Verify after install

Run the prompts in `REGRESSION-TESTS.md` and check the tool trace against the PASS/FAIL criteria.
Expose the connector calls so you can see whether `artifact_handoff` / `canmore` were invoked.
