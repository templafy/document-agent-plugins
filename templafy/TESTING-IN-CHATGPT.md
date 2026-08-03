# Testing the Templafy plugin in ChatGPT

For the full picture (App vs skills, build flags, submission) see `CHATGPT-DISTRIBUTION.md`; for the exact
prompts see `REGRESSION-TESTS.md`. This page is the quick "is it working?" checklist.

## First: which surface are you on?

- **Chat** — the Templafy **connector** tools are reachable (approved app installs one-click, or a custom
  connector via Developer Mode), but **skills don't route** here, so a plain "make a deck" tends to hit
  ChatGPT's built-in slide route. Invoke Templafy explicitly (`@Templafy …`) to use the connector in Chat.
- **Work / Codex** — the **skills** load and route deck requests to Templafy. **Do functional testing here.**

If the deck came back as a local `.pptx` built with the built-in slide tool, that is a **selection** outcome
(the built-in route was chosen before the Templafy skill), not a bug in the skill body.

### Recognising the two paths in a trace

- **Built-in (wrong):** "listed slide files and helpers", "validated package", "created … slides with shapes",
  `artifact_handoff.prepare_artifact_generation`, `python … python-pptx`, or `image_gen`.
- **Templafy (right):** `find_document_agents → list_themes → collect_presentation_context → generate_presentation_ui`.

## Step 1 — Confirm the skills work (isolate selection from behaviour)

In a Work/Codex session with the Templafy connector signed in, force the path:

> **"Use the Templafy skill to build this deck — do not use the built-in presentation/slides tool."**
> or **"@Templafy create a 5-slide company overview deck."**

- **PASS** (trace shows the Templafy path, generation view opens) → the skills work; any remaining problem is
  *selection*. Go to Step 2.
- **FAIL even when forced** (no `find_document_agents`, or a sign-in / "no tools" error) → the **connector isn't
  reachable** in that session. Enable/sign in the Templafy app first (`skills/connect-verify-templafy/`), retry.

## Step 2 — Make Templafy win without forcing it (Work/Codex)

Selection is agent/workspace configuration:

1. **Scope the agent to Templafy** so "make a deck" maps to the connector.
2. **Deprioritize the built-in slide / artifact / canvas generators** for that agent.
3. Keep **`create-branded-presentation`** prominent — its `agents/openai.yaml` sets
   `allow_implicit_invocation: true` and declares the Templafy MCP dependency.

Then re-run `REGRESSION-TESTS.md` Part A **without** forcing and confirm the trace stays on the Templafy tools.

## What is *not* the fix

- Rewriting skill bodies to "beat" the built-in — that only helps once the skill is **selected**; it does nothing
  about the selection race. (Failing-chat audits tend to suggest these; they assume the skill already ran.)
- Re-phrasing the user prompt — the built-in path wins on plain phrasing.
