# Distributing & submitting the Templafy ChatGPT plugin

The Templafy plugin bundles two things ChatGPT treats **separately**, and that distinction drives the plan:

- an **MCP-backed app (connector)** — the hosted `mcp.templafy.com` server, declared in `.mcp.json` (this stays
  in **every** build); `.app.json` is only an *optional* reference to a pre-registered app id, dropped by default; and
- **skills** — the `SKILL.md` routing/workflow guides under `skills/`.

| Piece | Chat | Work | Codex | Role |
|---|:---:|:---:|:---:|---|
| App / connector (MCP) | ✅ | ✅ | ✅ | Makes the Templafy tools callable |
| Skills | — | ✅ | ✅ | Route deck requests to Templafy; keep generation on-brand |

**The app/connector is what gives Chat coverage.** MCP apps work in Chat — an approved directory app installs
one-click (and can render UI), or a custom connector is enabled via Developer Mode (Settings → Connectors).
**Skills are Work/Codex only:** "plugins aren't available in Chat" refers to the *skills* wrapper, not the MCP
connector inside it. So in Chat the Templafy tools are reachable, but the routing guard does not run — a plain
"make a deck" still tends to hit ChatGPT's built-in slide route unless the Templafy connector/tools are invoked
explicitly. In **Work/Codex** the skills add the implicit routing that keeps deck requests on Templafy.

**Net: submit the App + skills together.** The App earns Chat + Work + Codex tool availability; the skills earn
better routing in Work/Codex. (Confirmed by testing: the published Templafy *app* works in Chat regardless of
skills; a plugin imported for its *skills* alone does nothing in Chat.)

## 1. Plugin contents (ChatGPT/Codex side)

```
WebApi.Mcp/plugins/templafy/
├── .codex-plugin/plugin.json     # Codex/ChatGPT manifest (name, version, skills, mcpServers, interface, apps*)
├── .mcp.json                     # remote Templafy connector (shared with Claude)
├── .app.json                     # optional pre-registered app id (asdk_app…) — EXCLUDED by default
└── skills/<name>/
    ├── SKILL.md                  # the workflow (shared with Claude)
    └── agents/openai.yaml        # Codex metadata: MCP dependency + allow_implicit_invocation
```

`.claude-plugin/` is Claude-only (Codex reads `.codex-plugin/`). `.mcp.json` is shared.

## 2. Build the upload artifact

`scripts/build-codex-zip.ps1` produces `dist-codex/templafy-codex.zip` (manifest at the archive root). The
`.mcp.json` MCP connector is kept in **every** build — this is a **full plugin**, not a skills-only wrapper.
Only the `.app.json` **app-id reference** is conditional:

- **Default — full plugin, no app-id reference** (skills + the `.mcp.json` MCP connector; drops only the
  registered `.app.json` id). **Use this for both submission and testing:**
  ```powershell
  pwsh scripts/build-codex-zip.ps1
  ```
- **Optional** — re-attach the registered app id if a build ever needs it:
  ```powershell
  pwsh scripts/build-codex-zip.ps1 -IncludeApp
  ```

Or run the submission wrapper, which builds the default artifact and checks submission-readiness (manifest
fields, connector URL, app-id absent) plus prints the manual checklist:
```powershell
pwsh scripts/build-submission.ps1
```

## 3. Import directly (admin workspace) or submit

- **Direct import (testing):** in a workspace where you're admin, import the built zip (or reference the folder
  via a `marketplace.json` `source.path`). Sign the Templafy connector in when prompted.
- **Submit:** portal at `platform.openai.com/plugins` (submission type **With MCP**). Needs assets
  (icon/logo/screenshots), a `brandColor`, privacy/terms URLs, domain verification (token at
  `/.well-known/openai-apps-challenge`), and **5 positive + 3 negative test cases** (see `REGRESSION-TESTS.md`).
  Fill the `interface` block in `.codex-plugin/plugin.json`. Build with `-IncludeApp`.

## 4. Test in Work mode (with the improved skills)

Install/import into a **Work** (or Codex) session with the Templafy connector signed in, then run the prompts in
`REGRESSION-TESTS.md`. A pass keeps the trace on the Templafy tools —
`find_document_agents → list_themes → collect_presentation_context → generate_presentation_ui` — with **no**
`artifact_handoff` and **no** local `.pptx`.

If the built-in slide route still wins selection in Work, the remaining levers are agent/workspace-level:

1. **Scope the agent to Templafy** so "make a deck" maps to the connector.
2. **Deprioritize the built-in slide / artifact / canvas generators** for that agent.
3. Keep **`create-branded-presentation`** prominent — its `agents/openai.yaml` sets
   `allow_implicit_invocation: true` and declares the Templafy MCP dependency.

> Chat-mode routing analysis (why the built-in slide route wins in Chat, the app-vs-skills split, the
> `presentation` router behavior) lives in the assistant's project memory, not here — this doc stays
> submission-focused.
