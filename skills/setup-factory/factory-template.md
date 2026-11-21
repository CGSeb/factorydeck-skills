# Factory

How this repository runs its agent workflow. The factorydeck skills (`write-spec`, `check-spec`, `build-feature`, `retro`) and the stop gate read this file. `/setup-factory` wrote it; edit it by hand whenever the workflow changes. Keep the `- Name: value` lines on one line each: the stop gate reads `Check command`, `Stop gate` and `Main branch` from them.

## Repository

- Git host: <GitHub | GitLab>
- Git host commands: `docs/agents/git-host.md`
- Main branch: `main`
- Merge method: squash

Every issue, pull request (merge request on GitLab), label, CI and merge operation the skills name in **bold** is a command of `docs/agents/git-host.md`.

## Agents

- Coding agents used here: <Claude Code, Codex, GitHub Copilot, …>
- Instructions file: `AGENTS.md`
- Project skills folder: `.agents/skills/`

## People

- Language for people: English
- Hand work to: `@me`

Every issue comment, question, pull request body and score report is written in the language for people. Skills, code and commit messages stay as the repository already writes them.

## Checks

- Check command: `<command that runs format, lint, types and tests>`
- Stop gate: on
- Verification skill: none

<Optional: narrower commands for one test file or one package, and anything a builder must know to run the checks: a database to start, a service to stub.>

## Specs

- Specs folder: `docs/specs/`
- Spec file name: `NNN-short-name.md`
- Product context: none

The spec format. Each line below names the text this repository uses for that part of a spec; the skills look for these exact strings.

| Part                 | Text in this repository  |
| -------------------- | ------------------------ |
| Status line          | `Status:`                |
| Status values        | `draft`, `ready`, `done` |
| Depends-on line      | `Depends on:`            |
| Checked line         | `Checked:`               |
| User goal section    | `## User goal`           |
| Criteria section     | `## Acceptance criteria` |
| Rules section        | `## Rules`               |
| Proof section        | `## Expected proof`      |
| Out-of-scope section | `## Out of scope`        |

## Issues

- Issue title: `NNN · Name`
- Dependencies: <blocking links of the git host | the depends-on line only>

| Role                           | Label              |
| ------------------------------ | ------------------ |
| A spec's issue                 | `spec`             |
| Ready to build                 | `agent:ready`      |
| An agent is building it        | `agent:working`    |
| Waiting for a product answer   | `agent:needs-spec` |
| Pull request waiting for merge | `agent:review`     |
| Blocked                        | `agent:blocked`    |

## Build

- Parallel workers: 3
- Branch name: `feat/<NNN>-<short-name>`
- Pull request title: `feat: <Subject>`
- Auto-merge: on
- Serenity threshold: 80
- Main branch protection: <on | off, and why>

<Commit convention, if the repository has one.>

## Protected paths

A pull request that changes one of these needs a person, whatever its score: they hold the rules the agents are graded by.

- `AGENTS.md`, `CLAUDE.md`, `docs/agents/`, the agents' config folders (`.claude/`, `.codex/`, `.github/`, …) except the verification skill's feature map
- <CI config, lint, type, test and formatter configs of this repository>
- <the product context, if any>

## Rules for the reviewer

<Project rules a reviewer must check that no tool enforces, one bullet each. « None » when there are none.>
