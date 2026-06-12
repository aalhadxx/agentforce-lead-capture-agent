# Lead Capture Agent for Agentforce

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Salesforce API](https://img.shields.io/badge/Salesforce%20API-v60.0-00A1E0)
![Agentforce](https://img.shields.io/badge/Agentforce-Service%20Agent-brightgreen)

> A minimal, open-source Agentforce Service Agent that captures lead information (last name + company) through a conversational multi-turn flow and creates a Salesforce Lead using a secure Apex invocable action.

---

## For AI Agents (Claude, Cursor, Copilot, etc.)

> **Start here.** If you are an AI assistant helping a developer deploy this agent, follow these exact steps in order. No plugins or external tools required — only the Salesforce CLI (`sf`).

### Prerequisites

```bash
# Verify Salesforce CLI is installed
sf --version

# Verify you are authenticated to a target org
sf org display --target-org <YOUR_ORG_ALIAS>
```

---

### Step 1 — Deploy Metadata

```bash
# Deploy all Apex classes, permission set, and agent bundle
sf project deploy start --target-org <YOUR_ORG_ALIAS>
```

Expected output: `Deploy Succeeded` with status `Succeeded`.

---

### Step 2 — Assign the Permission Set to the Agent User

```bash
# Find the Einstein Service Agent user
sf data query \
  --query "SELECT Id, Username FROM User WHERE Username LIKE '%agent%' LIMIT 5" \
  --target-org <YOUR_ORG_ALIAS>

# Assign the permission set (replace <USER_ID> with the Id from above)
sf data create record \
  --sobject PermissionSetAssignment \
  --values "AssigneeId=<USER_ID> PermissionSetId=$(sf data query --query \"SELECT Id FROM PermissionSet WHERE Name='LeadCaptureAgent_Apex_Access' LIMIT 1\" --target-org <YOUR_ORG_ALIAS> --json | python -c \"import json,sys; print(json.load(sys.stdin)['result']['records'][0]['Id'])\")" \
  --target-org <YOUR_ORG_ALIAS>
```

> **Known gotcha:** Without this permission set, `LeadCaptureTurnAction` will fail silently with no Lead created. The agent will loop asking for fields it already has.

---

### Step 3 — Preview Test the Agent

```bash
# Start a preview session
sf agent preview start \
  --json \
  --authoring-bundle LeadCaptureAgent \
  --use-live-actions \
  --target-org <YOUR_ORG_ALIAS>
# Note the sessionId from the output

# Test multi-turn: send company first
sf agent preview send \
  --json \
  --session-id <SESSION_ID> \
  --utterance "My company is Acme Corp" \
  --authoring-bundle LeadCaptureAgent \
  --target-org <YOUR_ORG_ALIAS>
# Expected: agent asks for last name

# Send last name to complete the lead
sf agent preview send \
  --json \
  --session-id <SESSION_ID> \
  --utterance "My last name is Smith" \
  --authoring-bundle LeadCaptureAgent \
  --target-org <YOUR_ORG_ALIAS>
# Expected: agent confirms lead created with a Lead ID

# End session and collect traces
sf agent preview end \
  --json \
  --session-id <SESSION_ID> \
  --authoring-bundle LeadCaptureAgent \
  --target-org <YOUR_ORG_ALIAS>
```

---

### Step 4 — Verify the Lead Was Created

```bash
sf data query \
  --query "SELECT Id, LastName, Company, Status FROM Lead ORDER BY CreatedDate DESC LIMIT 3" \
  --target-org <YOUR_ORG_ALIAS>
```

Expected result:

| Id | LastName | Company | Status |
|----|----------|---------|--------|
| 00QMB000... | Smith | Acme Corp | New |

---

### Step 5 — Publish and Activate (only when ready)

> **Do NOT publish yet if you are still testing.** Deploying and previewing does not affect production users. Publish only when you are satisfied with preview test results.

Go to **Setup → Agents → Lead Capture Agent → Publish → Activate**.

---

### Known Gotchas (AI agents: read carefully)

| Issue | Root Cause | Fix |
|-------|-----------|-----|
| Lead not created, agent loops | Permission set not assigned to agent user | Step 2 above |
| `leadId` binding error | `leadId` must be `String`, not `Id` type in Apex | Already fixed in `LeadCaptureTurnAction.cls` |
| `USER_MODE` insert fails | Agent user lacks `Lead` create permission | Included in `LeadCaptureAgent_Apex_Access` perm set |
| Preview session not found | `--authoring-bundle` flag missing on `send`/`end` | Always pass `--authoring-bundle` on all three subcommands |

---

## Architecture

```
User message
    ↓
[agent_router]  ← start_agent, handles greetings + routing
    ↓ transition
[lead_capture]  ← subagent
    ↓ invokes
[LeadCaptureTurnAction]  ← @InvocableMethod Apex
    ↓
  - Parses userMessage for last name / company via regex
  - Holds known values across turns via knownLastName / knownCompany inputs
  - Inserts Lead in USER_MODE when both fields are present
  - Returns isSuccess, leadId (String), resolvedLastName, resolvedCompany
    ↓
[Variables updated]  last_name, company, lead_created, last_lead_id
```

### Why Apex instead of Flow?

- **Multi-turn state**: Apex receives `knownLastName` and `knownCompany` as inputs per turn — the agent passes its own variables in, eliminating Flow's session limitations.
- **USER_MODE**: `Database.insert(..., AccessLevel.USER_MODE)` enforces FLS and CRUD on the agent user, avoiding over-privileged system context.
- **`leadId` as `String`**: Agentforce binds outputs more cleanly to `String` than `Id` type.

---

## File Reference

| File | Purpose |
|------|---------|
| `force-app/main/default/aiAuthoringBundles/LeadCaptureAgent/LeadCaptureAgent.agent` | Agent Script DSL definition |
| `force-app/main/default/classes/LeadCaptureTurnAction.cls` | Primary invocable Apex — parses message, holds state, creates Lead |
| `force-app/main/default/classes/LeadCreationAction.cls` | Minimal backup Lead creator (direct insert) |
| `force-app/main/default/permissionsets/LeadCaptureAgent_Apex_Access.permissionset-meta.xml` | Grants agent user access to Apex classes + Lead object |
| `sfdx-project.json` | SFDX project config |

---

## Contributing

Pull requests welcome. See `CONTRIBUTING.md`.

## License

MIT — see [LICENSE](LICENSE).
