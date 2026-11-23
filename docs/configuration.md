# Configuration

Nothing about your project is hard-coded. `docs/agents/factory.yml` holds every setting in plain YAML, validated by [a JSON Schema](../skills/setup-factory/factory.schema.json): edit it by hand, or from [FactoryDeck](https://github.com/CGSeb/factorydeck) once it connects your repositories. The skills read your spec headings, your labels, your check command, your models and your language from it. What needs more than a value goes in `docs/agents/factory-notes.md`, one section each: notes on the checks, the commit convention, main branch protection and the rules for the reviewer. `docs/agents/git-host.md` holds the exact `gh` or `glab` command for each operation the skills name, so a CLI that changes a flag is fixed in one place. Keep an existing spec format; `setup-factory` maps it instead of replacing it.

Instructions for agents go to `AGENTS.md`. With Claude Code, `CLAUDE.md` imports it with a single `@AGENTS.md` line.

## Requirements

- `git`.
- **GitHub**: the [GitHub CLI](https://cli.github.com/), logged in (`gh auth login`). **GitLab**: the [GitLab CLI](https://gitlab.com/gitlab-org/cli), logged in (`glab auth login`). GitLab's blocking links between issues need Premium or Ultimate; on the free tier, dependencies live in each spec's depends-on line, which the skills read anyway.
- A POSIX shell for the stop gate: any Linux or macOS shell, Git Bash or WSL on Windows.

To install the skills, see the [README](../README.md#install). For the hard limits around the agents, see [Guardrails](guardrails.md).
