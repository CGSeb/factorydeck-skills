# Starting and talking to agents

`build-feature` needs four things from the coding agent that runs it. Each one has a fallback, so the workflow runs everywhere; the fallbacks cost tokens or independence, never correctness.

| Need | Claude Code | Codex | Without it |
| --- | --- | --- | --- |
| **Start a background agent** with a prompt and its description (`SKILL.md`) | `Agent` tool with `run_in_background: true` and the description in `description` | `spawn_agent` (needs `multi_agent = true` under `[features]` in Codex's `config.toml`) | Run the role yourself, one issue at a time (see below) |
| **Start several at once** | several `Agent` calls in one message | several `spawn_agent` calls in one response | One at a time |
| **Wait for a report** | you are notified when one finishes; never poll | `wait_agent` | — |
| **Write to an agent that already reported** | `SendMessage` with its id | send it input if the installed Codex can; otherwise the fallback | Start a fresh agent with the same role, worktree and the message (see below) |
| **Wait for an external change** (step 5b: a pull request a person merges) | `Monitor` with a loop that exits when the change happens, or a scheduled wake-up when Monitor is missing; you are notified, never poll yourself | a background shell loop it is told about when it exits, if the installed Codex has one | Tell the person « say when #<pr> is merged », and resume at step 5b when they do |
| **Start an agent on the model of its role** (`agents.models` of `docs/agents/factory.yml`) | the `model` parameter of `Agent` | the model option of `spawn_agent`, if the installed Codex has one | The session's model |

Other agents (GitHub Copilot, Gemini CLI, Cursor, …): use their subagent or delegation feature when it can run a prompt in a given directory and return its final message; otherwise use the fallbacks.

## Fresh agent instead of a message

The worktree and the pull request body file hold the worker's state. A fresh worker given « You are resuming issue #<n> in worktree `<path>`. Read `<skill dir>/worker.md`, then the pull request body at `<path to body>` and `git log origin/<main>..HEAD`, then handle this: <the message> » picks up where the last one stopped. It costs a re-read of the issue and the diff, not a rebuild.

## Without background agents

Run the roles yourself, one issue at a time, in the order of `SKILL.md`, working in the issue's worktree:

- Read `worker.md` and build; then **clear what you know of the build** before reviewing: start a new session or conversation for the review if your agent allows it, so the reviewer reads the branch cold. A review by the agent that wrote the code is weaker: say so in the score breakdown and subtract 10 points (« review not independent »).
- Read `shipper.md` and ship.
- Score with `serenity.md`.

Never skip the review or the gates because the roles share one agent.
