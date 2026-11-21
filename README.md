# FactoryDeck skills

Skills for running a software factory of coding agents on any project: write and check specs, build features with independent review and a merge gate, prove them in the real app, and learn from each run.

They are plain Markdown plus `git` and the GitHub CLI. No Node, no Python, no Docker, nothing to build: they work in any language and on any stack. The only script is a POSIX shell hook.

> Status: early. Built for Claude Code first; the skills follow the Agent Skills format, so other agents can read them too.

## The workflow

```text
/setup-factory  ──▶  /write-spec  ──▶  /check-spec  ──▶  /build-feature  ──▶  /retro
  once per repo       one per feature    settles open      workers, review,      learn from
                      + its issue        product choices   score, merge          the run
```

| Skill | What it does |
| --- | --- |
| `setup-factory` | Explores the repository and writes `docs/agents/factory.md`: GitHub repository, spec format, labels, check command, merge policy, protected paths. Adds guardrails to `.claude/settings.json`. Run it once. |
| `write-spec` | Interviews you on a feature, writes a spec with testable acceptance criteria, opens its GitHub issue with its dependencies. |
| `check-spec` | Finds every product choice a spec leaves open and gets it settled, with you or as questions on the issue. |
| `build-feature` | The orchestrator. One background worker per buildable issue, each in its own git worktree; a fresh reviewer before any push; a cheap shipper for push, pull request and CI; gates and a serenity score decide whether it merges or goes to you. |
| `create-verification-skill` | Generates `verify-<app>`, a project-local skill that launches your app, drives it like a user and keeps evidence, with a feature map. Workers use it to prove each criterion. |
| `maintain-verification-skill` | Keeps that feature map honest as the app changes. |
| `retro` | Reads a session's logs and proposes changes to checks, skills, reviewer rules and `CLAUDE.md`, so the next run goes better. |

The plugin also installs a **stop gate**: before an agent stops with work that is not on the main branch yet, it runs your check command and sends the agent back while it fails (three times at most). It does nothing in a repository without `docs/agents/factory.md`, and `Stop gate: off` there turns it off.

## Install

In Claude Code:

```text
/plugin marketplace add CGSeb/factorydeck-skills
/plugin install factorydeck-skills@factorydeck
```

Then, in your project:

```text
/setup-factory
```

You need `git`, the [GitHub CLI](https://cli.github.com/) logged in, and a POSIX shell for the stop gate (any Linux or macOS shell, Git Bash or WSL on Windows).

## Your project, your vocabulary

Nothing about your project is hard-coded. `docs/agents/factory.md` is ordinary prose and tables that you can edit by hand: the skills read your spec headings, your labels, your check command and your language from it. Keep an existing spec format; `setup-factory` maps it instead of replacing it.

## Guardrails

A rule written in a skill can be argued with; a platform setting cannot. So the hard limits live in the platform:

- **Claude Code permissions**: `setup-factory` denies reading `.env` files, pushing to the main branch and force-pushing.
- **GitHub branch protection** (public repositories, or paid plans for private ones): required CI checks and an up-to-date branch before any merge.
- **The merge gate** in `build-feature`: a pull request that touches the rules agents are graded by, adds a lint or test suppression, or edits a migration always goes to a person.

## Measuring the factory

[FactoryDeck](https://github.com/CGSeb/factorydeck) reads your Claude Code sessions and shows what each issue and each role (worker, reviewer, shipper) cost, the review rounds, the outcomes and the frictions. The skills work without it.

## Credits

`create-verification-skill` and `maintain-verification-skill` are adapted from [pstack](https://github.com/cursor/plugins/tree/main/pstack) by Lauren Tan, and `setup-factory` and `retro/writing.md` draw on [mattpocock/skills](https://github.com/mattpocock/skills), both MIT. See [CREDITS.md](CREDITS.md).

## License

[MIT](LICENSE)
