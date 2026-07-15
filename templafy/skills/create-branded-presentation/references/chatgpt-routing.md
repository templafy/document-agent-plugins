# ChatGPT routing: keeping presentation requests on Templafy

## What goes wrong (observed in production)

In ChatGPT (especially enterprise), a "make a presentation / slides" request triggers ChatGPT's own built-in
slide/artifact routing. After the correct Templafy steps (find agents → list themes → user picks a theme), the
model gets pulled into non-Templafy tools:

- `artifact_handoff.prepare_artifact_generation` — fires repeatedly, even after the user says "only Templafy"
  or "skip artifact_handoff".
- ChatGPT's built-in **`presentations`** skill — a native skill that builds a deck with pptxgenjs/python-pptx.
  It often wins *skill selection* outright, so a "make a deck" request never reaches the Templafy skill at all.
  Tell-tale trace steps: "listed slide files and helpers", "created directory, validated package, and inspected
  functions and scripts", "created … slides with shapes and images".
- `canmore.create_textdoc` / `canmore.update_textdoc` — canvas notes, unrelated to generation.

The model then wrongly concludes "Templafy is disabled/unavailable" and stops — even though the Templafy tools
are still present and were working moments earlier.

> **Selection vs. behaviour.** This guard only helps once the Templafy skill is *selected*. If ChatGPT's
> built-in `presentations` skill is picked first, this skill never runs — that is a workspace/agent
> configuration problem (deprioritize the built-ins), not something a skill body can fix. See
> `TESTING-IN-CHATGPT.md`.

## The rule

For a Templafy presentation, the only tools that touch generation are Templafy's. Any built-in
slide/artifact/canvas tool — and any local file generation (python-pptx, LibreOffice, a hand-built `.pptx`) —
is off-limits for this task, no matter what the environment suggests.

## On-rails checklist

1. `find_document_agents` (prompt = the user's goal). `Ok` → use the `agentId`; `NeedsSelection` → numbered
   list, wait for the user.
2. `list_themes` (pass the `agentId`). `NeedsSelection` → numbered list, wait. It requires a valid `agentId` —
   never call it empty.
3. **After the theme is chosen → `collect_presentation_context`** (omit `sessionId` on the first call; then
   supply `message` + `agentDefinitionId` + `themeId` per the tool's schema). This is the step that gets
   dropped — do not divert to `artifact_handoff`/canvas here.
4. Follow `workflow.nextTool`: on `PrepareOutline` → `generate_presentation_ui` with the returned `sessionId`.

## Recovery from a routing mistake

If a non-Templafy tool was invoked by accident, acknowledge it plainly and resume from the last successful
Templafy state — reuse the known `agentId`, `themeId`, `sessionId`, and the user's requirements, and continue
with the next correct Templafy tool rather than restarting from scratch.

## When Templafy's later tools seem to "disappear" after theme selection

Seen repeatedly in ChatGPT with the bare connector: after `find_document_agents` + `list_themes`, the model
asks the user to pick a theme; on the next turn `collect_presentation_context` / `generate_presentation_ui`
aren't in the immediate tool list, and the model wrongly decides "Templafy has no more actions" / "the next
action isn't exposed beyond theme selection", emits no-op `python` calls, or builds a local `.pptx` instead.
The tools didn't go away — ChatGPT just didn't re-list them this turn (connector tools are surfaced on demand).

Recover: re-discover the connector's tools (e.g. `api_tool.list_resources` for `Templafy`, or a tool search),
then call `collect_presentation_context` with the saved `agentDefinitionId` + `themeId` + the user's brief
(all ids as **strings**; `sessionId: null` on the first call) and continue until `PrepareOutline`, then
`generate_presentation_ui`. Never tell the user Templafy is unavailable, never stop at the theme step, and
never fill the gap with no-op `python`.

Also: `find_document_agents` returns the agent id as a **number**, but `list_themes` and
`collect_presentation_context` want it as a **string** — stringify every id before passing it on, or the call
fails schema validation (`… is not of type 'string'`).

## The widget hand-off is normal — don't misread it

`generate_presentation_ui` returning `generationId: null` + `PrepareOutline` is the **normal** widget handoff
(by design — the widget then handles outline prep, generation, and polling), **not** a failure. Tell the user
the presentation is being generated. If **no widget renders** after that handoff, that's a client/app-side
rendering issue (the `outputTemplate` widget didn't display), **not** a routing mistake: do not fall back to
built-in tools or claim Templafy is broken; hand to `troubleshoot-templafy-mcp`.
