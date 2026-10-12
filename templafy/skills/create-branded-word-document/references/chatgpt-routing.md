# ChatGPT routing: keeping document requests on Templafy

## What could go wrong

A "write a letter / memo / report" request can get pulled into ChatGPT's own built-in document handling
before the Templafy skill ever runs — the same selection mechanism `create-branded-presentation` guards
against for decks. For Word documents the competing built-ins are:

- `canmore.create_textdoc` / `canmore.update_textdoc` — canvas's document-drafting mode, which writes and
  edits a text document directly instead of calling Templafy.
- Any other built-in "create a document / file" tool, or a code-based generator (python-docx, LibreOffice,
  a hand-built `.docx`).

This is a same-mechanism risk, not a reported incident the way the deck-selection race is (see
`create-branded-presentation/references/chatgpt-routing.md` and `TESTING-IN-CHATGPT.md` for that
confirmed case) — there is no equivalent audit log for Word yet. Treat this section as the guard to apply
if the same symptom shows up here.

## The rule

For a Templafy Word document, the only tools that touch generation are Templafy's
(`compose_word_document`, and whichever of `get_word_document` / `generate_word_ui` its `workflow` names
next — see the main `SKILL.md`). Any built-in document/canvas tool, and any local file generation, is
off-limits, no matter what the environment suggests.

## On-rails checklist

1. Call `compose_word_document` directly with the document as Markdown. Unlike presentations, there is no
   agent or theme to select first — never route through `find_document_agents` or `list_themes` for a
   Word request.
2. Keep sending sections (same `sessionId`) until the document is complete, then set `final: true`.
3. Follow the returned `workflow` to the next tool. Don't invent a different next step and don't fall back
   to a built-in if a step is momentarily missing from the tool list — re-discover the connector's tools
   instead of concluding Templafy is unavailable.

## The widget handoff is normal — don't misread it

On a widget-capable host, `generate_word_ui` returning `Ready` is the **normal** handoff (by design — the
widget then handles polling and shows the download link), **not** a failure. Tell the user the document is
being generated. If no widget renders after that handoff, that's a client/app-side rendering issue, not a
routing mistake: do not fall back to a built-in tool or claim Templafy is broken — use
`troubleshoot-templafy-mcp`.

## Recovery from a routing mistake

If a non-Templafy tool was invoked by accident, acknowledge it plainly and resume from the last known
`sessionId` — reuse it and continue with the correct Templafy tool rather than restarting from scratch or
handing off the non-Templafy draft.
