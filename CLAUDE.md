# FactoryDeck skills

A Claude Code plugin of skills for running a software factory of coding agents on any project. See `README.md`.

## Rules for every change

- **No dependencies.** Skills are Markdown that call `git` and `gh`. A script is the last resort, and then POSIX `sh` only (no bash-isms, no `jq`, no Node or Python): it must run with `dash`.
- **No project in the skills.** Never name a repository, path, label, language, stack or command of a particular project. Anything project-specific is read from `docs/agents/factory.md`; a new setting goes in `skills/setup-factory/factory-template.md` and in the questions of `setup-factory`.
- **One source of truth.** Each rule lives in one file; others point to it. A setting the stop hook reads stays a one-line `- Name: value` entry in the template.
- Every skill folder is listed in `.claude-plugin/plugin.json`. Bump its `version` when a change should reach installed users.
- Adapted material keeps its credit in `CREDITS.md` and in the skill.
- Write skills in English, for an agent reading them cold. Before writing one, read `skills/retro/writing.md`.

## Check before committing

```bash
for f in .claude-plugin/*.json hooks/hooks.json; do python3 -m json.tool "$f" >/dev/null || echo "invalid: $f"; done
```

```bash
dash -n hooks/before-stop.sh
```

```bash
grep -L '^name:' skills/*/SKILL.md
```

The last one must print nothing: every `SKILL.md` has frontmatter with a `name`. Then try the changed skill on a real repository.
