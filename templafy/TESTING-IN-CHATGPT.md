# Testing the Templafy skills in ChatGPT

If you tried the Templafy skills in ChatGPT and it built the deck with its own slide tool instead —
**that is expected in the current setup, and it is not a bug in the skills.** This guide explains why, how
to test correctly, and how to make Templafy win for real.

## TL;DR

- The skills are fine. The problem is **selection**: ChatGPT picks its own built-in `presentations`
  skill / `artifact_handoff` slide route for "make a deck" *before* the Templafy skill is chosen, so the
  Templafy skill never runs.
- Loose skills sitting next to the **published Templafy App** (they were **not** bundled into the App) have
  the weakest possible selection signal, so they lose that race almost every time.
- To test the skills work at all: **force the Templafy path explicitly** (below).
- To make Templafy win **without** forcing it: use a **Workspace/Agent** that deprioritizes the built-in
  slide tools and enables the Templafy connector (below).

## Why this happens

1. **The skills are loose, not bundled.** They were added separately from the published Templafy App, before
   ChatGPT had the plugin concept. Loose `SKILL.md`s carry only a name + description — no connector binding and
   no `allow_implicit_invocation` policy. That is the weakest signal ChatGPT has for choosing a skill.
2. **ChatGPT added a built-in `presentations` skill.** It builds decks with pptxgenjs/python-pptx and is
   weighted heavily for exactly the phrase "make a presentation / deck / slides." It out-competes a loose
   third-party skill on selection.
3. **A mandatory pre-route.** Presentation requests are pushed into `artifact_handoff.prepare_artifact_generation`
   before other tools, which also front-runs the Templafy skill.

Net effect: `make a deck` → built-in `presentations` / `artifact_handoff` → a local `.pptx`, and the Templafy
skill + connector are never reached. This is **selection**, not skill content — a skill that is not selected
cannot run its own rules.

### How to recognize the built-in path in a trace

You are on the built-in path (not Templafy) if you see steps like:

- "Listed slide files and helpers"
- "Created directory, validated package, and inspected functions and scripts"
- "Created … slides with shapes and images"
- `artifact_handoff.prepare_artifact_generation`, `python_user_visible.exec` with `python-pptx`, or `image_gen.text2im`

You are on the Templafy path if you see: `find_document_agents` → `list_themes` → `collect_presentation_context`
→ `generate_presentation_ui`.

## Step 1 — Confirm the skills actually work (force the path)

This isolates *selection* from *behaviour*. In a chat where the Templafy connector is enabled, be explicit:

> **"Use the Templafy skill to build this deck — do not use the built-in presentation/slides tool."**

or invoke the connector directly:

> **"@Templafy create a 5-slide company overview deck."**

**Expected (PASS):** the trace shows `find_document_agents` → `list_themes` (you pick a theme) →
`collect_presentation_context` → `generate_presentation_ui`, and the Templafy generation view opens.

- If it **PASSES** → the skills are working; your only problem is selection. Go to Step 2.
- If it **FAILS** even when forced (no `find_document_agents`, or a sign-in / "no tools" error) → the **Templafy
  connector is not actually reachable** in that session. Confirm the published App/connector is enabled and
  signed in first (see `skills/connect-verify-templafy/`), then retry.

## Step 2 — Make Templafy win *without* forcing it (the durable fix)

Selection is a workspace/agent-configuration problem. Create a **Workspace or custom Agent** and:

1. **Enable the Templafy connector** on that Agent.
2. **Disable / deprioritize the competing built-ins** for that Agent — Canvas, image generation, and especially
   the built-in **slide / presentation / artifact generator** (the `presentations` skill and `artifact_handoff`).
   If ChatGPT cannot make slides itself, it cannot intercept.
3. **Add a top-level Agent instruction** (this sits above skill selection and intercepts earliest):
   > *"All presentation / deck / PowerPoint requests must use the Templafy connector. Never use the built-in
   > slide, presentation, artifact, or canvas generators."*
4. **Add the Templafy skills** to that Agent, and keep `create-branded-presentation` prominent.

Then re-run the prompts in `REGRESSION-TESTS.md` **without** forcing, and confirm the trace stays on the
Templafy tools.

## Step 3 — Fix it at the source (recommended for real rollout)

Loose skills will always be the weakest option. Bind the skills to the connector so they ship as one unit:

- **Bundle the skills into the published App.** The App submission portal has a **Skills** section; re-submit the
  Templafy App with the skills included so the published App carries them (they are currently separate).
- **Or distribute the plugin** (`.codex-plugin/plugin.json` + each skill's `agents/openai.yaml`, which set
  `allow_implicit_invocation: true` and declare the Templafy MCP dependency) for the Codex / ChatGPT Work
  surface. See `CHATGPT-DISTRIBUTION.md`.

Either replaces "loose skill, weak signal" with "bound skill, strong signal" — the single biggest improvement to
selection.

## What is *not* the fix

- Rewriting the skill bodies. Every "add a rule inside the skill" idea only helps once the skill is **selected**;
  it does nothing about the selection race. (Audit files generated by the failing chat tend to suggest these —
  they assume the skill ran.)
- Re-phrasing the user prompt. The built-in path wins on the plain phrasing; wording tweaks do not reliably beat
  a native skill.

## Quick reference

| Symptom | Cause | Action |
|---|---|---|
| Deck built with pptxgenjs/python-pptx; no `find_document_agents` | Built-in `presentations`/`artifact_handoff` won selection | Step 2 (Agent config); Step 3 (bundle skills) |
| Forced Templafy path works, unforced does not | Pure selection problem | Step 2 |
| Forced path also fails (no Templafy tools / sign-in error) | Connector not reachable | Enable/sign in the connector; `connect-verify-templafy` |
| Skills present but never listed as chosen | Loose install, weak signal | Step 3 (bundle into App or ship the plugin) |
