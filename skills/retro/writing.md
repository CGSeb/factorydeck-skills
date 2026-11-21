# Writing for agents

How to write a skill, an `AGENTS.md`, a reviewer rule or an agent's global instructions. Adapted from Matt Pocock's `writing-for-agents` skill (https://github.com/mattpocock/skills, MIT).

## Two budgets

- **Context load**: what sits in every agent's window on every turn: `AGENTS.md` (or `CLAUDE.md`), each skill's `description`. Every word there costs on every turn of every agent, workers included.
- **On demand**: a skill's body, `reviewer.md`, a doc reached through a pointer. Loaded only when needed.

Put material as low as it can go: a check before a sentence, a reviewer rule before an `AGENTS.md` line, a pointer to a doc before the doc's content.

## Pointers

A line that names other material (a skill `description`, a row of the repository map) must say what the material is and when to reach it, one trigger per distinct case. Its wording decides whether the agent reaches the material: sharpen it before inlining the material.

## Steps

- Each step ends on a **done** condition the agent can check (« Done when every signal is tied to a cause or dismissed »). A vague bound invites stopping early.
- Demanding wording drives the digging: « every criterion traced to a test » beats « check the tests ».

## Pruning

- **One source of truth**: each rule lives in one place. Elsewhere, point to it.
- **The environment is a source of truth**: do not restate `package.json` scripts, configs or `--help` output. Write what the agent cannot find by looking: an unwritten convention, the reason behind a choice, a gotcha.
- **No-ops**: delete any sentence the agent would follow anyway. Delete the whole sentence rather than trimming it.
- **Positive phrasing**: state the target behaviour (« write one-line comments »), not the banned one; a prohibition is only for a hard guardrail, paired with what to do instead.
- **Sprawl**: a long file thins attention even when each line is right. Split by branch: what only some cases need goes behind a pointer.
