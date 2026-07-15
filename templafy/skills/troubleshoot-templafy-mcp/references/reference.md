# Templafy troubleshooting matrix

Read the tool's actual return first; translate findings into plain language for the user (don't expose raw
internal terms).

| Symptom | Likely cause | What to do |
|---|---|---|
| Tool call "blocked by OpenAI's safety checks" / "couldn't determine the safety status" | ChatGPT's connector safety gate rejecting the call **upstream**, before Templafy sees it — content-independent (a benign "coffee presentation" is blocked too), often transient for a newly-added connector; **not** a Templafy or auth fault | Don't rephrase-loop and don't fall back to a built-in; retry once after a short wait, invoke Templafy explicitly (`@Templafy`), confirm the connector is authorized; if it persists it's an OpenAI-side false positive → escalate to OpenAI / workspace admin |
| Templafy tools absent / OAuth / 401 | Not connected / not signed in | Hand to `connect-verify-templafy` (add server, sign in, confirm tenant module + egress to `*.templafy.com`) |
| `find_document_agents` errors "no agents" | Prompt matched nothing, or no agents accessible to this account | Broaden the neutral prompt; if still none, it's a tenant/admin setup matter |
| `list_themes` fails, called with no `agentId` | Bare call — it requires an agent id | Get an `agentId` from `find_document_agents` first; never bare-probe `list_themes` |
| `list_themes` returns empty | No themes configured for the tenant, OR the service is briefly unavailable | Confirm the connection via `find_document_agents`; if healthy, it's tenant/admin provisioning |
| Generation times out at the chat surface | Long-running job exceeded the chat tool-call window; the job may still be running | Don't assume the deck is lost; re-check status; avoid a blind regenerate (duplicates) |
| Generation stuck for several minutes | Genuinely stuck past the stall threshold | Report the stalled step; escalate to Templafy support; don't fall back to built-in tools |
| `generate_presentation_ui` returns `generationId: null` + `PrepareOutline` | **Normal handoff** — this is by design; the widget then takes over outline prep, generation, and polling. Not a failure. | Tell the user the presentation is being generated in the Templafy view, and stop; wait for the widget |
| Handoff returns normally but **no widget / preview renders** in the client | Client / app-side widget rendering issue — the `outputTemplate` widget didn't display (seen in ChatGPT); **not** the null generation id | Report "the generation view didn't render after handoff" and escalate to the Templafy team / support; do **not** switch generators |
| Flow stops after theme selection; model says Templafy has "no more actions" / the next step is "not exposed beyond theme selection", or emits no-op `python` | ChatGPT hasn't re-listed the connector's later tools this turn — they're surfaced on demand, not gone | Re-discover the connector's tools (`api_tool.list_resources` for `Templafy` / tool search), then call `collect_presentation_context` (ids as strings, same session) through to `PrepareOutline`; don't claim unavailable or fall back |
| `list_themes` / `collect_presentation_context` rejects the agent id (`… is not of type 'string'`) | `find_document_agents` returns the id as a number; downstream tools require a string | Stringify the id before passing it on (server-side, agents should return string ids like themes already do) |
| A non-Templafy `.pptx` was produced | ChatGPT's native slide/artifact route intercepted the request | See `create-branded-presentation`; deprioritize/disable built-in slide tools for the Templafy agent |
| Missing download / PDF link | Generation didn't reach completion | Diagnose via the timeout / widget rows above |

**Escalation:** persistent connection or widget-render issues are server/tenant-side → the user's Templafy
administrator or `support.templafy.com`. Always give the concrete symptom (which step, what the tool returned).
