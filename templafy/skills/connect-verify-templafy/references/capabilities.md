# Templafy readiness signals

Determine readiness from tool presence and one broad, neutral `find_document_agents` probe — never from a
version number.

| Signal | Meaning | Action |
|---|---|---|
| `find_document_agents` not in the tools list | Not connected | Onboard — see `setup.md` |
| `find_document_agents` → auth / sign-in / 401 error | Not signed in | Onboard / re-authenticate — see `setup.md` |
| `find_document_agents` → agents returned | Ready | Proceed to the user's task |
| `find_document_agents` → "no agents found" on a broad prompt | Prompt-based search matched nothing — connected, but nothing matched (not proof the tenant is empty, not a failure) | Report as "no matching/available agents found"; suggest a broader request or checking Templafy setup |
| First `find_document_agents` call **blocked by an OpenAI/host safety check** (not an auth error) | ChatGPT's connector safety gate upstream — not evidence Templafy is missing, and content-independent | Don't treat it as "not connected" and don't rephrase-loop the prompt; often transient for a new connector — retry once shortly with Templafy invoked explicitly. Persisting → OpenAI-side false positive to escalate (see `troubleshoot-templafy-mcp`). Don't fall back to another tool |
| A specific tool call fails after a good probe | Transient / service issue | Hand off to `troubleshoot-templafy-mcp` |

Notes:

- `find_document_agents` searches by the prompt you pass; a narrow prompt can return nothing even when agents
  exist. Probe with a broad, neutral phrase before concluding anything about the tenant.
- `list_themes` requires a valid `agentId`; never call it as a bare connectivity check.
- `serverInfo.version` is not readable from here — rely on the signals above, not a version string.
- Future: if a read-only `get_templafy_mcp_status` tool is added, prefer it for an explicit version +
  capability handshake; until then these tool-presence signals are the contract.
