# Agent coordination

**The agent-to-agent tool surface — how a fleet of coding agents finds each
other, stays out of each other's way, hands work over, and asks a human.**

`agent-coord` is the fleet-coordination MCP server: one `POST /mcp` endpoint
(JSON-RPC 2.0, MCP streamable HTTP, protocol `2025-03-26`) exposing seventeen
tools. Any agent whose profile lists it gets the whole surface — no per-agent
wiring.

It fronts three planes behind that one endpoint:

| Plane | Holds | Backed by |
|---|---|---|
| **Control plane** | identity, task ownership, lineage, phase, pending human prompts | `Agent` / `AgentTask` / `AgentChannel` / `HumanPrompt` CRs on `fastverk.savvifi.com/v1` |
| **Fabric** | live message bytes, presence, the offer→accept handshake | NATS core subjects |
| **Blackboard** | resource claims, semantic focus, durable audit | JetStream KV (`agent-claims`, `agent-focus`) + the `agent-events` stream |

The rule that shapes the split: never put cursor-level churn in etcd, never put
durable provenance in a message that can drop.

## Choosing a primitive

Seventeen tools, but only a handful of decisions.

- **`claim` / `release`** — you are about to *touch* something (a file, a symbol,
  a named resource) and another agent might be touching it too. Take a TTL lease
  on an exact key first. This is a **cooperative advisory lock**: nothing
  enforces it, and a crashed holder's lease expires rather than wedging the
  resource forever.
- **`annotate` / `find_agents`** — you want to know *who is working on what*,
  fuzzily. `annotate` publishes your free-text intent plus file/symbol/concept
  tags; `find_agents` keyword-scans the fleet's annotations. Use this to find a
  peer worth talking to; use `check_claims` to find out whether one specific
  thing is already spoken for.
- **`send`** — one message, one recipient, fire-and-forget. No reply, no
  delivery guarantee: core NATS drops a message that has no live subscriber.
- **`open_channel`** — a *durable* rendezvous for a known set of agents. The
  `AgentChannel` CR is the record (participants, subject, TTL, phase) and NATS
  auth scopes the subject to exactly those participants; the bytes still ride
  NATS. Reach for this when a conversation will outlive a single message and
  needs to be discoverable and access-scoped.
- **`broadcast`** — fleet-wide fan-out on one subject. No addressing, no reply,
  no guarantee. Announcements only.
- **`handoff`** — you are giving a task *away*, with context. A synchronous
  offer→accept handshake: the call blocks until the successor accepts or rejects,
  or the deadline passes. Use it when your context window is running out, when
  the work needs a different specialist, or when a supervisor delegates.
- **`escalate`** — the work needs a *human* decision. It raises a `HumanPrompt`
  CR, which the console renders, and waits for the answer on a reply subject. The
  CR is durable, so an unanswered prompt outlives the waiting call — and, in the
  full suspend flow, outlives the agent process itself.
- **`checkpoint` / `resume`** — externalize state so a Job can die and come back.
  `resume` is a spawn with `resumeFrom` pointed at the last checkpoint.

Resume, handoff, and human-prompt-suspend are the same primitive seen three
ways: checkpoint then rehydrate later, checkpoint then rehydrate *elsewhere*,
checkpoint then suspend until answered.

## Getting the tools

An agent does not configure this server itself. The chain:

**1. The `AgentProfile` lists it.**

```yaml
apiVersion: fastverk.savvifi.com/v1
kind: AgentProfile
metadata:
  name: migrator
spec:
  backend: claude-code
  mcpServers:
    - agent-coord
    - meridian-mcp
```

**2. The `Agent` controller** joins `spec.mcpServers` with spaces into the runner
Job's `MCP_SERVERS` env, alongside `AGENT_ID`, `AGENT_INBOX_SUBJECT` and
`AGENT_STATUS_SUBJECT`.

**3. `agent-runner`'s entrypoint** synthesizes an MCP config file from that list
and launches the backend with `--mcp-config <file> --strict-mcp-config`. Each
bare name resolves to:

| Setting | Env override | Default |
|---|---|---|
| URL | `MCP_<NAME>_URL` | `http://<name>.<ns>.svc.cluster.local:8080/mcp` |
| Transport | `MCP_<NAME>_TYPE` | `http` (MCP streamable HTTP) |
| Bearer token | `MCP_<NAME>_TOKEN` | none |
| Extra headers | `MCP_<NAME>_HEADERS` (a JSON object) | none |
| Forge identity | `MCP_<NAME>_FORGE_IDENTITY` | off |

`<NAME>` is the server name upcased with dashes turned into underscores, so
`agent-coord` reads `MCP_AGENT_COORD_URL`. Pointing `MCP_CONFIG` at a mounted
file bypasses synthesis entirely — the escape hatch for servers that need stdio
or a bespoke transport.

The in-cluster default already resolves `agent-coord` correctly, so a profile
that names it needs no other wiring.

### Identity is an argument, not a credential

Unlike the per-user console plugins, `agent-coord` holds no forwarded user token.
Every tool acts as the fleet service **on behalf of the agent id the call
carries** — the `agent` or `from` argument, which is the runner's `AGENT_ID`.
That id is asserted by the caller, not authenticated by the server. The real
boundary is the per-agent NATS account, which scopes the subjects an agent can
actually publish to and subscribe from.

## Tool reference

Arguments are the `arguments` object of a `tools/call`. Every string argument is
optional with an empty default unless marked required; a missing required
argument fails the call with `` `<key>` is required ``. Array arguments also
accept a comma-separated string.

### Discovery

#### `list_agents`

Lists the fleet's `Agent` CRs.

| Argument | Type | Required | Notes |
|---|---|---|---|
| `selector` | string | no | Kubernetes label selector, e.g. `fastverk.savvifi.com/pool=web`. Empty means all. |

Returns `{"agents": [...]}`, one condensed row per Agent —
`{name, profile, pool, phase, focus, labels}`. `phase` reads `Unknown` until the
operator writes status.

*Fails when* the selector is malformed or the service account cannot list Agents
in its namespace.

#### `get_agent`

| Argument | Type | Required | Notes |
|---|---|---|---|
| `name` | string | **yes** | The `Agent` CR name. |

Returns `{"found": true, "agent": {...}}` or `{"found": false}`. A missing agent
is **not** an error.

#### `find_agents`

Fuzzy peer discovery over the `agent-focus` KV.

| Argument | Type | Required | Notes |
|---|---|---|---|
| `query` | string | **yes** | Free text, e.g. `auth ci-migration`. |

The query is lowercased and split on whitespace; an agent matches if **any** term
appears as a substring of its concatenated intent, files, symbols and concepts.
Returns `{"matches": [{agent, intent, concepts, files}]}` — unranked and
unbounded.

*Caveat:* an agent that has never called `annotate` is invisible here even while
its `Agent` CR is running. Keyword search today; the tool signature is the seam
for embeddings later.

### Annotation and claims

#### `annotate`

Publishes the calling agent's live focus.

| Argument | Type | Required | Notes |
|---|---|---|---|
| `agent` | string | **yes** | The annotating agent's id. |
| `intent` | string | no | Free text: what you are working on. |
| `files` | string[] | no | File paths in view. |
| `symbols` | string[] | no | Symbols in view. |
| `concepts` | string[] | no | Fuzzy tags. |

Returns `{"ok": true, "agent": "<id>"}` and appends an `AGENT_ANNOTATED` audit
event.

*This is a whole-record write, not a merge.* Fields you omit are cleared — send
the full focus every time.

#### `claim`

Takes a TTL lease on one exact resource key via an atomic compare-and-set
(`create` succeeds only if the key is absent), so two agents racing for the same
key cannot both win.

| Argument | Type | Required | Default | Notes |
|---|---|---|---|---|
| `agent` | string | **yes** | | The claiming agent's id. |
| `resource_key` | string | **yes** | | Exact key, e.g. `file:aion/web:src/auth.rs`, `symbol:AuthService`, `resource:RepoReadiness/aion-web`. |
| `mode` | string | no | `read` | `read`, `write`, or `intent`. |
| `ttl` | string | no | `5m` | Go-style duration. |

On success: `{"acquired": true, "revision": <u64>, "claim": {...}}`, plus a
`CLAIM_ACQUIRED` audit event. On contention:
`{"acquired": false, "holder": {...}}` — back off or negotiate with the holder.
Contention is a *result*, not an error.

Sharp edges worth knowing:

- **`mode` fails soft.** Anything that is not `write` or `intent` parses as
  `read`, typos included.
- **Only single-unit `ttl` values parse** (`90s`, `5m`, `1h`). Anything else
  yields an empty `expires_at` — no *logical* expiry — and the claim then lives
  until the bucket's `max_age` (`AGENT_CLAIM_TTL_SECONDS`, default 900s) reaps
  it.
- **Keys are sanitized to the NATS KV charset.** Everything outside
  `[-/_=.a-zA-Z0-9]` becomes `_`, so `file:aion/web:src/auth.rs` is stored as
  `file_aion/web_src/auth.rs`. Two keys differing only in punctuation collide on
  one lease.
- **`mode` gates nothing.** A `read` claim and a `write` claim contend
  identically; the mode is advisory metadata for whoever reads it.

#### `release`

| Argument | Type | Required | Notes |
|---|---|---|---|
| `agent` | string | **yes** | Must be the current holder. |
| `resource_key` | string | **yes** | The claimed key. |

Returns `{"released": true}`, or `{"released": false}` when nothing was held.
*Fails* with `claim on <key> is held by <other>, not <agent>` when you are not
the holder — an agent may only drop its own lease.

#### `check_claims`

| Argument | Type | Required | Notes |
|---|---|---|---|
| `prefix` | string | no | Resource-key prefix filter, e.g. `file:aion/web:`. Empty means all. |

Returns `{"claims": [{resource_key, agent, mode, ttl, expires_at}]}`.
Logically-expired leases are filtered out even when the KV row has not aged out
yet. The prefix matches the *original* `resource_key` carried in the claim, not
the sanitized KV key. Each key is fetched individually, so cost is linear in the
number of live claims.

### Lifecycle

#### `spawn_subagent`

| Argument | Type | Required | Default | Notes |
|---|---|---|---|---|
| `profile` | string | **yes** | | The `AgentProfile` to spawn from. |
| `name` | string | no | `<profile>-<hex-ms>` | Explicit `Agent` name; the default stem is DNS-1123-sanitized. |
| `pool` | string | no | | Worker pool (`Agent.spec.pool`). |
| `prompt` | string | no | | Initial objective. |

Returns `{"name": "<agent>", "profile": "<profile>"}` and emits `AGENT_SPAWNED`.

`prompt` is **not** an `Agent` spec field. When given, the tool first creates an
`AgentTask` named `<name>-task` carrying `spec.objective` and
`spec.assignedAgentRef`, then creates the `Agent` with `spec.ownerRef` pointing
at it. Task-first ordering keeps the pair coherent on a retry.

*Creation is idempotent, not upsert:* an existing name is returned as-is and its
spec is left untouched, so re-spawning a name with a different profile silently
keeps the old one.

#### `cancel`

| Argument | Type | Required | Notes |
|---|---|---|---|
| `name` | string | **yes** | An `Agent` or `AgentTask` name. |
| `reason` | string | no | Carried as the control message body. |

There is no `spec.cancel` field: the stop signal is *deleting* the CR, and the
operator's `ownerReference` GCs the backing runner Job. The tool deletes the
`Agent` if one exists by that name, otherwise the `AgentTask`. It then sends a
best-effort `MESSAGE_CONTROL` to `agents.<name>.inbox` so a live runner can drain
gracefully; a failure there is ignored.

Returns `{"cancelled": true, "name": "<name>"}`. *Fails* when neither an Agent
nor a task by that name exists.

### Messaging

#### `send`

| Argument | Type | Required | Default | Notes |
|---|---|---|---|---|
| `from` | string | **yes** | | Sender agent id. |
| `to` | string | **yes** | | Recipient agent id. |
| `body` | string | no | `""` | Opaque payload, sent as UTF-8 bytes. |
| `kind` | string | no | `text` | `text`, `offer`, `accept`, `reject`, `control`. |
| `correlation_id` | string | no | | Request/reply pairing key. |

Returns `{"sent": true, "to": "<id>", "subject": "agents.<id>.inbox"}`.

*`sent: true` means published, not delivered.* This is core NATS: with no live
subscriber on the inbox the message is dropped and the tool still reports
success. An unrecognized `kind` falls back to `text` silently.

#### `open_channel`

| Argument | Type | Required | Notes |
|---|---|---|---|
| `name` | string | **yes** | Channel name; becomes the `AgentChannel` CR name. |
| `members` | string[] | no | Agent ids — written to `spec.participants`. |
| `topic` | string | no | Preserved as the label `fastverk.savvifi.com/topic`. |

Returns `{"channel": "<name>", "subject": "channels.<name>"}`.

`AgentChannelSpec` validates `participants` with `MinItems=1`, so a call with no
`members` is rejected by the API server. `topic` has no spec field, so it is
label-safed (alphanumeric-bounded, ≤63 chars) rather than dropped. Creation is
idempotent — reopening an existing channel does not add participants.

#### `broadcast`

| Argument | Type | Required | Notes |
|---|---|---|---|
| `from` | string | **yes** | Sender agent id. |
| `body` | string | no | Opaque payload. |

Returns `{"sent": true, "subject": "agents.broadcast"}`. Always `MESSAGE_TEXT` —
there is no `kind` argument. Same fire-and-forget caveat as `send`, amplified:
nobody is required to be listening.

### Handoff, merge, escalate

#### `handoff`

Transfers a task to a successor over a **blocking** NATS request-reply
handshake.

| Argument | Type | Required | Default | Notes |
|---|---|---|---|---|
| `from` | string | **yes** | | The handing-off agent id. |
| `to` | string | **yes** | | The successor agent id. |
| `summary` | string | no | | Where things stand. |
| `branch` | string | no | | Git WIP branch the successor continues on. |
| `remaining` | string[] | no | | Outstanding work items. |
| `artifact_refs` | string[] | no | | S3/OCI refs (checkpoints, diffs, logs). |
| `timeout_secs` | integer | no | `30` | Handshake deadline. |

The four context fields are packed into an `agent.v1.HandoffContext` proto and
sent as a `MESSAGE_OFFER` to `agents.<to>.inbox`. The call blocks for the
successor's `MESSAGE_ACCEPT` or `MESSAGE_REJECT`.

Returns `{"accepted": <bool>, "reply_kind": <int>, "from": "<replier>"}`, and
emits `HANDED_OFF` only on accept.

*Fails* with `handoff offer to <to> timed out` when nothing replies in the
window — which is also what you get if the successor is not running, since core
NATS request-reply has no queue behind it.

*Scope:* this tool performs the handshake and the audit event. It does not by
itself create the successor `AgentTask` or write handoff lineage onto the CRs;
that is the operator's half of the flow.

#### `merge`

| Argument | Type | Required | Notes |
|---|---|---|---|
| `target_task` | string | **yes** | The `AgentTask` that absorbs the work. |
| `source_task` | string | **yes** | The `AgentTask` being merged in. |

Records the linkage by merge-patching `spec.lineage.mergedFrom` on the target and
emits `MERGED`. Returns `{"merged": true, "target": ..., "source": ...}`.

*This is a skeleton.* It records provenance; the actual branch and artifact fold
is the operator's job. And because it is a JSON merge patch, the `mergedFrom`
array is **replaced** rather than appended — merging a second source overwrites
the record of the first.

#### `escalate`

Raises a human decision and waits for the answer.

| Argument | Type | Required | Default | Notes |
|---|---|---|---|---|
| `agent` | string | **yes** | | The escalating agent id. |
| `question` | string | **yes** | | The question for the human. |
| `timeout_secs` | integer | no | `60` | How long to wait. |

Creates a `HumanPrompt` CR named `prompt-<hex-ms>` with `spec.kind: notify` and a
`meridianSpec` carrying an info notification, emits `HUMAN_PROMPTED`, then
subscribes to `prompts.<id>.reply` for up to `timeout_secs`.

Returns `{"prompt": "<id>", "answered": <bool>, "answer": "<text>|null"}`.

An unanswered window is **not** a failure: `answered: false` comes back and the
`HumanPrompt` stays open for the console to resolve later. Two things to know:

- The subscription is created *after* the CR is raised, so an implausibly fast
  answer published in that gap is missed — core NATS has no replay.
- This tool sends a *notification*-kind prompt. Structured approvals, choices and
  form input are `meridian-mcp`'s tools (`request_approval`, `ask_choice`,
  `request_input`), which drive the same `HumanPrompt` CRD with a real response
  schema and the checkpoint-and-suspend round trip. Both servers belong in
  `AgentProfile.mcpServers`.

### Checkpoint and resume

#### `checkpoint`

| Argument | Type | Required | Notes |
|---|---|---|---|
| `task` | string | **yes** | The `AgentTask` name. |
| `ref` | string | **yes** | The checkpoint blob ref, e.g. `s3://.../ck-3`. |
| `sha` | string | no | Git WIP sha at snapshot. |
| `tokens_used` | integer | no | Context tokens consumed. |
| `summary` | string | no | Short progress summary. |

Appends a `CheckpointMeta` to `AgentTask.status.checkpoints[]` with a JSON Patch
(`add /status/checkpoints/-`), so the append-only history is preserved rather
than overwritten, and emits `CHECKPOINTED`. Returns `{"task": ..., "ref": ...}`.

Only the *pointer* rides the control plane. The bundle itself — git WIP bundle,
context archive, metadata — is the S3 blob at `ref`, written by the runner.

*Fails* when `status.checkpoints` does not already exist on the task: a JSON
Patch `add` to `/-` requires the parent array to be present.

#### `resume`

| Argument | Type | Required | Notes |
|---|---|---|---|
| `task` | string | **yes** | The `AgentTask` to resume. |
| `profile` | string | **yes** | The profile to rehydrate into. |
| `name` | string | no | Explicit Agent name; defaults like `spawn_subagent`. |
| `pool` | string | no | Worker pool. |

Reads the **last** entry of `status.checkpoints[]` and spawns a fresh Agent with
`spec.resumeFrom` set to that ref, emitting `RESUMED`. Returns
`{"agent": "<name>", "resumed_from": "<ref>"}`.

*Fails* with `AgentTask <task> has no recorded checkpoint to resume from` when
the task has never checkpointed. "Latest" means last-appended, not
newest-by-timestamp.

## The transport underneath

### Subjects

The subject namespace is defined once, in the operator's `api/v1/fabric.go`; the
Rust units mirror it.

| Subject | Carries |
|---|---|
| `agents.<id>.inbox` | direct messages and handoff offers |
| `agents.<id>.status` | presence heartbeat + live focus stream |
| `agents.broadcast` | fleet-wide fan-out |
| `channels.<chan-id>` | one `AgentChannel`'s duplex bytes |
| `agents.pool.<pool>` | a subagent pool's queue group |
| `prompts.<id>.reply` | a human prompt's answer |
| `agents.events` | the durable audit stream's subject |

Per-agent NATS accounts and JWTs scope which of these an agent may publish to or
subscribe from — an agent cannot read another's inbox unless it is invited to a
channel. That, not the `agent` argument, is the real access boundary.

### Wire format

Every byte on every subject is an `agent.v1` protobuf. The envelope:

```proto
message ChannelMessage {
  string from = 1;           // sender agent id
  string to = 2;             // recipient agent id ("" on channel/broadcast)
  string channel = 3;        // AgentChannel name when this rides a channel
  MessageKind kind = 4;      // TEXT | OFFER | ACCEPT | REJECT | CONTROL
  bytes body = 5;            // opaque payload
  string ts = 6;             // RFC 3339
  string correlation_id = 7; // request/reply + offer/accept pairing
}
```

`body` is opaque — sender and receiver agree on it out of band — except for
`handoff`, where it is an encoded `HandoffContext`.

### Durable state

| Store | Kind | Holds |
|---|---|---|
| `agent-claims` | JetStream KV | `resource_key → Claim`, atomic-CAS TTL leases. Bucket `max_age` from `AGENT_CLAIM_TTL_SECONDS` (default 900s), history 1. |
| `agent-focus` | JetStream KV | `agent → Focus`, the corpus `find_agents` scans. No expiry. |
| `agent-events` | JetStream stream | `AgentEvent` lifecycle records: spawned, annotated, claim acquired/released, checkpointed, handed off, merged, human prompted/answered, suspended, resumed, task completed/failed. |

Audit publishing is best-effort by design: a failed `agent-events` append is
logged, never surfaced as a tool error, because the coordination action itself
already happened.

`AgentChannel` is the durable half of a conversation — participants, resolved
subject, TTL, phase (`Pending`/`Open`/`Closed`/`Expired`) — while the bytes stay
on NATS. The CR earns its place as the low-frequency rendezvous record and the
NATS-auth scope, not as a message log.

## Calling it directly

The server is plain JSON-RPC over HTTP, so it is easy to poke from inside the
cluster:

```sh
curl -sS http://agent-coord.fastverk.svc.cluster.local:8080/mcp \
  -H 'content-type: application/json' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
```

`initialize` reports `protocolVersion 2025-03-26` and
`serverInfo {name: "agent-coord"}`. `GET /healthz` returns `ok`. There is no
other route — `agent-coord` is a pure tool provider with no UI panel of its own.

### How errors arrive

Per the MCP spec, a tool that *fails* still returns a JSON-RPC **result**, with
`isError: true` and the error chain as text, so the model can see and recover
from it:

```json
{"content": [{"type": "text", "text": "`resource_key` is required"}], "isError": true}
```

Genuine protocol errors are the only JSON-RPC `error` responses: `-32601` for an
unknown method, `-32602` for an unknown tool name. A successful call returns both
a text rendering and a `structuredContent` object holding the JSON documented
above.
