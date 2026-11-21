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
- Model for spec checks: session default
- Model for workers: session default
- Model for reviewers: session default
- Model for shippers: session default

Each model is a name the coding agent that runs `build-feature` accepts when it starts a subagent, or `session default`. When several coding agents run it, give one name per agent: `<model> (Claude Code), <model> (Codex)`. An agent that cannot choose a subagent's model, or does not know the name, uses its own.

## People

- Language for people: English
- Hand work to: `@me`

Every issue comment, question, pull request body and score report is written in the language for people. Skills, code and commit messages stay as the repository already writes them.

## Checks

- Check command: `<command that runs format, lint, types and tests>`
- Stop gate: on
- Verification skill: none
- Services check: none
- Services start: none

<If the checks or the verification need shared services (a database, a container engine), « Services check » is a command that succeeds only when they answer, and « Services start » the command that starts them from the main checkout. Say here what the person must start by hand when the check fails (a desktop application, a VPN): agents never start it themselves.>

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
- Branch name: `<the repository's branch pattern, with the spec number and a short name>`
- Commit convention: <the repository's own: its instructions file, commit hook or recent history | none>
- Pull request title: `<the commit convention's form for a new feature, with the subject>`
- Auto-merge: on
- Serenity threshold: 80
- Main branch protection: <on | off, and why>

<The commit convention in full, with an example for each kind of change a builder makes (a feature, a fix, a test, docs), when the repository has one. With a squash merge, the pull request title becomes the commit on the main branch, so it follows the same convention.>

## Protected paths

A pull request that changes one of these needs a person, whatever its score: they hold the rules the agents are graded by.

- `AGENTS.md`, `CLAUDE.md`, `docs/agents/`, the agents' config folders (`.claude/`, `.codex/`, `.github/`, …) except the verification skill's feature map
- <CI config, lint, type, test and formatter configs of this repository>
- <the product context, if any>

## Rules for the reviewer

<Project rules a reviewer must check that no tool enforces, one bullet each. « None » when there are none.>
