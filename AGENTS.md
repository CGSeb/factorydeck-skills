# FactoryDeck skills

A plugin of Agent Skills for running a software factory of coding agents on any project, with any coding agent, on GitHub or GitLab. See `README.md`.

## Rules for every change

- **No dependencies.** Skills are Markdown that call `git` and the git host's CLI. A script is the last resort, and then POSIX `sh` only (no bash-isms, no `jq`, no Node or Python): it must run with `dash`.
- **No project in the skills.** Never name a repository, path, label, language, stack or command of a particular project. Anything project-specific is read from `docs/agents/factory.yml`, or from `docs/agents/factory-notes.md` when it needs more than a value; a new setting goes in `skills/setup-factory/factory-template.yml` and `factory.schema.json` (or a section of `factory-notes-template.md`), and in the questions of `setup-factory`.
- **No agent in the skills.** Write « start a background agent », not a tool name. What differs between coding agents lives in `skills/setup-factory/coding-agents.md` and `skills/build-feature/coding-agents.md`, one row per agent, with a fallback for agents not listed. Instructions files are `AGENTS.md`.
- **No git host in the skills.** A skill names an operation in **bold** (**Open a pull request**); its command lives in both `skills/setup-factory/git-host-github.md` and `git-host-gitlab.md`. A new operation goes in both files, with the same name.
- **One source of truth.** Each rule lives in one file; others point to it. A setting the stop gate reads stays a `key: value` line two spaces under its top-level section, in plain block YAML.
- Every skill folder is listed in `.claude-plugin/plugin.json` and has `agents/openai.yaml` (Codex metadata; `allow_implicit_invocation: false` for a skill with `disable-model-invocation: true`). Bump the plugin `version` when a change should reach installed users.
- Adapted material keeps its credit in `CREDITS.md` and in the skill.
- Write skills in English, for an agent reading them cold. Before writing one, read `skills/retro/writing.md`.

## Check before committing

```bash
for f in .claude-plugin/*.json hooks/hooks.json skills/setup-factory/factory.schema.json; do python3 -m json.tool "$f" >/dev/null || echo "invalid: $f"; done
```

```bash
dash -n hooks/before-stop.sh
```

```bash
for d in skills/*/; do [ -f "$d/SKILL.md" ] && grep -q '^name:' "$d/SKILL.md" && [ -f "$d/agents/openai.yaml" ] || echo "incomplete: $d"; done
```

```bash
grep -rnE '\b(gh|glab) ' skills --exclude-dir=setup-factory --include=SKILL.md --include=worker.md --include=reviewer.md --include=shipper.md --include=serenity.md
```

The last two must print nothing (the last one: CLI commands belong in the git host files). Then try the changed skill on a real repository.
