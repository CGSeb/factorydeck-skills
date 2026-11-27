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

## Every role

Workers, debuggers, reviewers and shippers follow these rules from their first command. Each one removes calls that real runs saw refused or failed, whatever the language of the repository.

- **A command fails only when something failed.** A step whose failure is a normal answer (a search that finds nothing, a file that may be missing, two files that differ, a status command that exits non-zero while checks are pending) ends with `|| true`, or goes in a call of its own. A build, a test or the check command keeps its exit code.
- **Name a secrets file only to test that it exists.** A file git ignores that holds secrets (`.env`, a local settings, properties or credentials file) is often denied to agents, and a denial refuses the whole chained command around it. Run `test -e <file> && echo present || echo missing` in a call of its own; never list, read, print or copy it.
- **Wait on a condition, never on a fixed delay.** For CI, **Watch CI** returns when the checks end; for a server or a file, loop on the condition with a bound (`for i in $(seq 1 60); do <check> && break; sleep 2; done`). Run either as « Wait for a long command » below says.
- **Read a file before you edit it**, as « Edit a file » below says, and send an edit only when it changes the text.

| Need | Claude Code | Codex | Without it |
| --- | --- | --- | --- |
| **Edit a file** | open it with the `Read` tool in this session before `Edit` or `Write` (shell output of `cat`, `sed` or `grep` does not count); an `Edit` whose old and new text are equal is refused | `apply_patch` on lines you have read | the agent's edit command, on lines you have read |
| **Wait for a long command** | `run_in_background: true`, then wait for its notification; a `sleep` of more than a few seconds is refused | run it in the foreground with a long enough timeout | run it in the foreground |
| **Task list and summary** | none: the task-list and wrap-up tools of the desktop app (`update_plan`, `wrap_up`) are refused to sub-agents | none | none: the report is the only output |

## Fresh agent instead of a message

The worktree and the pull request body file hold the worker's state. A fresh worker given « You are resuming issue #<n> in worktree `<path>`. Read `<skill dir>/worker.md`, then the pull request body at `<path to body>` and `git log origin/<main>..HEAD`, then handle this: <the message> » picks up where the last one stopped. It costs a re-read of the issue and the diff, not a rebuild.

## Without background agents

Run the roles yourself, one issue at a time, in the order of `SKILL.md`, working in the issue's worktree:

- Read `worker.md` and build; then **clear what you know of the build** before reviewing: start a new session or conversation for the review if your agent allows it, so the reviewer reads the branch cold. A review by the agent that wrote the code is weaker: say so in the score breakdown and subtract 10 points (« review not independent »).
- Read `shipper.md` and ship.
- Score with `serenity.md`.

No agent description names the issue or the role here, so end the message that finishes each role with the work item line of `write-spec` step 4: `Work item: #<issue> (builder)` after building or reworking, `(reviewer)` after each review, `(shipper)` after shipping and scoring. Each line ties the work since the previous one to that issue and role.

Never skip the review or the gates because the roles share one agent.
