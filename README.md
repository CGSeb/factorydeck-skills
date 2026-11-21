# FactoryDeck skills

Skills for running a software factory of coding agents on any project: write and check specs, build features with independent review and a merge gate, prove them in the real app, and learn from each run.

They are plain Markdown plus `git` and your git host's CLI (`gh` for GitHub, `glab` for GitLab). No Node, no Python, no Docker, nothing to build: they work in any language, on any stack, with Claude Code, Codex, GitHub Copilot and other agents that read [Agent Skills](https://agentskills.io). The only script is an optional POSIX shell hook.

> Status: early. Used daily with Claude Code on GitHub; Codex, Copilot and GitLab follow the same files but have had less use. Reports welcome.

## The workflow

```text
/setup-factory  ──▶  /write-spec  ──▶  /check-spec  ──▶  /build-feature  ──▶  /retro
  once per repo       one per feature    settles open      workers, review,      learn from
                      + its issue        product choices   score, merge          the run
```

| Skill | What it does |
| --- | --- |
| `setup-factory` | Explores the repository and asks you, one section at a time: GitHub or GitLab, which coding agents, spec format, labels, check command, merge policy. Writes `docs/agents/factory.yml`, `docs/agents/factory-notes.md` and `docs/agents/git-host.md` (the exact CLI commands for your host, checked against your installed CLI), plus each agent's guardrails. Run it once. |
| `write-spec` | Interviews you on a feature, writes a spec with testable acceptance criteria, opens its issue with its dependencies. |
| `check-spec` | Finds every product choice a spec leaves open and gets it settled, with you or as questions on the issue. |
| `build-feature` | The orchestrator. One background worker per buildable issue, each in its own git worktree; a fresh reviewer before any push; a cheaper shipper for push, pull or merge request and CI; gates and a serenity score decide whether it merges or goes to you. Agents without background subagents run the same roles one after another. |
| `create-verification-skill` | Generates `verify-<app>`, a project-local skill that launches your app, drives it like a user and keeps evidence, with a feature map. Workers use it to prove each criterion. |
| `maintain-verification-skill` | Keeps that feature map honest as the app changes. |
| `retro` | Reads a session's logs (Claude Code or Codex) and proposes changes to checks, skills, reviewer rules and `AGENTS.md`, so the next run goes better. |

## Install

Pick one route per agent: installing twice gives you every skill twice.

<details>
<summary><strong>Claude Code</strong></summary>

In a Claude Code session:

```text
/plugin marketplace add CGSeb/factorydeck-skills
/plugin install factorydeck-skills@factorydeck
```

The plugin also installs the stop gate (see below).

</details>

<details>
<summary><strong>Codex</strong></summary>

```bash
codex plugin marketplace add CGSeb/factorydeck-skills
codex plugin add factorydeck-skills@factorydeck
```

`build-feature` starts subagents: enable them in `~/.codex/config.toml` with `[features]` then `multi_agent = true` (`/setup-factory` offers to do it).

</details>

<details>
<summary><strong>GitHub Copilot</strong> (CLI and VS Code)</summary>

```bash
copilot plugin marketplace add CGSeb/factorydeck-skills
copilot plugin install factorydeck-skills@factorydeck
```

In VS Code, run **Chat: Install Plugin From Source** and enter `https://github.com/CGSeb/factorydeck-skills`.

</details>

<details>
<summary><strong>Gemini CLI</strong></summary>

```bash
gemini skills install https://github.com/CGSeb/factorydeck-skills.git --path skills
```

Re-run it to update.

</details>

<details>
<summary><strong>Any other agent</strong> (Cursor, OpenCode, Windsurf, Amp…), or editable copies</summary>

With [skills.sh](https://skills.sh):

```bash
npx skills@latest add CGSeb/factorydeck-skills -a <agent>
```

Or copy the folders of `skills/` into your agent's skills folder (`.agents/skills/` in the project for most agents). Take them all: `build-feature` reads its role files beside its `SKILL.md`, and `setup-factory` its templates.

</details>

Then, in your project, run `/setup-factory` (or ask your agent to « run the setup-factory skill »).

### Requirements

- `git`.
- **GitHub**: the [GitHub CLI](https://cli.github.com/), logged in (`gh auth login`). **GitLab**: the [GitLab CLI](https://gitlab.com/gitlab-org/cli), logged in (`glab auth login`). GitLab's blocking links between issues need Premium or Ultimate; on the free tier, dependencies live in each spec's depends-on line, which the skills read anyway.
- A POSIX shell for the stop gate: any Linux or macOS shell, Git Bash or WSL on Windows.

## Your project, your vocabulary

Nothing about your project is hard-coded. `docs/agents/factory.yml` holds every setting in plain YAML, validated by [a JSON Schema](skills/setup-factory/factory.schema.json): edit it by hand, or from [FactoryDeck](https://github.com/CGSeb/factorydeck) once it connects your repositories. The skills read your spec headings, your labels, your check command, your models and your language from it. What needs more than a value goes in `docs/agents/factory-notes.md`, one section each: notes on the checks, the commit convention, main branch protection and the rules for the reviewer. `docs/agents/git-host.md` holds the exact `gh` or `glab` command for each operation the skills name, so a CLI that changes a flag is fixed in one place. Keep an existing spec format; `setup-factory` maps it instead of replacing it.

Instructions for agents go to `AGENTS.md`. With Claude Code, `CLAUDE.md` imports it with a single `@AGENTS.md` line.

## Guardrails

A rule written in a skill can be argued with; a platform setting cannot. So the hard limits live in the platforms:

- **Main branch protection** on the git host: CI must pass and the branch must be up to date before any merge. GitLab offers it on every tier; GitHub on public repositories, or private ones on paid plans.
- **Agent permissions**: `setup-factory` denies Claude Code reading `.env` files, pushing to the main branch and force-pushing, and sets the closest equivalent for the other agents.
- **The merge gate** in `build-feature`: a pull request that touches the rules agents are graded by, adds a lint or test suppression, or edits a migration always goes to a person.

### Stop gate

`hooks/before-stop.sh` runs your check command before an agent stops with work that is not on the main branch yet, and sends it back while the check fails (three times at most). It does nothing in a repository without `docs/agents/factory.yml`, and `checks.stop_gate: false` there turns it off. The Claude Code plugin installs it; any other agent with a stop hook can call `sh <plugin folder>/hooks/before-stop.sh` (exit code 2 means « keep working »).

## Measuring the factory

[FactoryDeck](https://github.com/CGSeb/factorydeck) reads your agent sessions and shows what each issue and each role (worker, reviewer, shipper) cost, the review rounds, the outcomes and the frictions. The skills work without it.

## Credits

`create-verification-skill` and `maintain-verification-skill` are adapted from [pstack](https://github.com/cursor/plugins/tree/main/pstack) by Lauren Tan. `setup-factory`, the git host files and `retro/writing.md` draw on [mattpocock/skills](https://github.com/mattpocock/skills). Both are MIT. See [CREDITS.md](CREDITS.md).

## License

[MIT](LICENSE)
