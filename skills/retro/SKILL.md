---
name: retro
description: "Retrospective on an agent session (Claude Code, Codex or another agent). Reads the session log and proposes changes to the agents' environment (checks, skills, AGENTS.md, reviewer rules, tooling) so the next run goes better. Use when asked for a retro or a retrospective, or to learn from a session that went badly."
disable-model-invocation: true
---

# Retro

You improve the agents' **environment**, not the code. Every struggle in a session is a symptom: ask what in the repository let it happen, and propose the check, pointer, rule or tool that prevents it next time. You only **propose**; nothing changes until the person picks a candidate.

Write to the person in `people.language` of `docs/agents/factory.yml` when it exists, otherwise in the language they use.

## 1. Pick the session

- No session named: the current one. Its struggles are still in your context, but compacted parts are not: read its log too.
- A session named (an id, a date, « yesterday's session », « the build of #38 »): find its log.

Where the logs are, one JSON object per line:

| Agent | Session logs |
| --- | --- |
| Claude Code | `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects/<project folder>/<session id>.jsonl`, where the project folder is the session's working directory with every `/` and `.` turned into `-`. Subagents (workers, reviewers, shippers) write to `<session id>/subagents/agent-<id>.jsonl` beside it, with their description in `agent-<id>.meta.json`. |
| Codex | `${CODEX_HOME:-$HOME/.codex}/sessions/<year>/<month>/<day>/rollout-*.jsonl`, one file per session; find the right one by its date and its first user message. |
| Others | Ask the person where their agent keeps its transcripts, or for an export of the session. |

List the latest with `ls -t`. Read only the current project's logs: the same folders hold the person's other conversations.

If FactoryDeck tracks this repository, start from its frictions view for the session, then read the raw log around each signal it shows.

## 2. Gather the evidence

The log is too big to read whole. Find the signals with `grep`, then read the lines around each one:

| Signal | Find it with (Claude Code field names; Codex logs use their own, so look at a few lines first) |
| --- | --- |
| What the person typed (corrections are the strongest signal) | Claude Code: lines with `"type":"user"` whose `"content"` is a string, not an array |
| Failed tool calls | `"is_error":true`, or a non-zero exit code |
| Calls a permission rule, a hook or the person denied | `denied`, `rejected`, `hook blocking error` |
| The stop gate sending the agent back | `factorydeck stop gate`, `The check command` |
| Compactions (context ran out) | `compact` |
| Commands run again and again | `grep -o '"command":"[^"]*"' <log> \| sort \| uniq -c \| sort -rn \| head` |
| Tools by count | `grep -o '"name":"[A-Za-z_]*"' <log> \| sort \| uniq -c \| sort -rn` |
| Largest results | `awk '{ print length, NR }' <log> \| sort -rn \| head` then read those line numbers |

`grep -n` gives line numbers; read around one with `sed -n '<from>,<to>p' <log>`, cut to what you need (`cut -c1-2000`). `jq` makes this easier where it is installed, but is never required.

Then:

- For each signal worth a look, read what the agent was trying and what it did next.
- A `build-feature` session: also read the score reports on its pull requests (**Read pull request comments** in `docs/agents/git-host.md`): review findings, score deductions, rejected findings.

Done when every signal is either tied to a cause or dismissed as noise (a `grep` with no match, an expected exit code).

## 3. Find the candidates

For each cause, pick its category; the category says where the fix lands.

| Category | Symptom in the session | Fix lands in |
| --- | --- | --- |
| Automated check | A mistake a tool could catch (it reached review, CI or the person) | The repository's linter, type checker or tests, a CI step, an agent hook or permission rule |
| Reviewer rule | A judgement-call mistake the reviewer let through | `reviewer_rules` in `docs/agents/factory.yml` |
| Navigation | Many calls to find a file, a command or a fact | A pointer from a file the agent already reads: `AGENTS.md`, a skill |
| Procedure | An agent took a wrong path in a skill's steps, or a step was missing or vague | The skill's own file, or `docs/agents/factory.yml` when the step is project-specific |
| Tool economy | A call returned far more than needed, or the same command ran again and again | A narrower command, a structured output, a cheaper model for the step |
| Information access | The agent needed something it could not reach (a log, a service, a decision) | A log written to a file, a read-only access, a question a skill asks earlier |
| Steering | `AGENTS.md`, a skill or the person's global instructions hold lines that change nothing | Delete them, or move them to a check or to the reviewer |

Before proposing a check, read the existing ones (the check command, linter and test configs, CI config, the agents' settings): a check that exists but is not wired, or misses this case, is the finding. A **mechanical** mistake (a banned API, an import shape, a file location, a missing file) always gets a check, never a sentence. Only a **judgement call** becomes prose, and that prose goes to the reviewer, where there is room for it, not to `AGENTS.md`, which every agent loads on every turn.

A fix to a factorydeck skill itself (a step every project would hit) is a candidate too: propose it as an issue or pull request on the skills' repository, not as a local edit.

A preference of the person that holds across all their projects goes to their agent's global instructions (`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, …), not to the repository.

Done when every candidate points to a specific moment of the session. Drop any you cannot trace: generic advice is noise.

## 4. Present them

Most severe first (what cost the most time, tokens or the person's attention, or could ship a bug). For each one:

- **Moment**: time and what happened, quoting the log briefly.
- **Cause**: what in the environment let it happen.
- **Proposal**: the category, the file and the change, concrete enough to apply as is.
- **Cost**: what it adds to always-loaded context (an `AGENTS.md` line, a skill description) or to the checks' run time.

Then ask the person which ones to apply, and stop.

## 5. Apply what the person picked

- Work on a branch from an up-to-date main branch.
- Before writing a skill, an `AGENTS.md`, a reviewer rule or global instructions, read [writing.md](writing.md).
- A new check must fail on the real mistake of the session: reproduce it, watch the check go red, then fix or revert the reproduction.
- Run `checks.command` of `docs/agents/factory.yml`. Commit and open the pull request only when the person asks.
