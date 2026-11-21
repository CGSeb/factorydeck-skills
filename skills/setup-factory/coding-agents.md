# Agent-specific setup

What `setup-factory` does for each coding agent the team uses. The skills themselves are the same for every agent; only these files and settings differ. When an agent is not listed, apply the closest equivalent its documentation offers, and say what had none.

## Instructions file

`AGENTS.md` at the repository root is the instructions file most coding agents read (Codex, GitHub Copilot, Cursor and others; check the documentation of any other agent). Claude Code reads `CLAUDE.md` instead: when Claude Code is used, `CLAUDE.md` holds the line `@AGENTS.md`, which imports it.

- Neither file exists: create `AGENTS.md`, and `CLAUDE.md` with `@AGENTS.md` if Claude Code is used.
- Only `AGENTS.md`: edit it; add `CLAUDE.md` with `@AGENTS.md` if Claude Code is used.
- Only `CLAUDE.md`: ask the person whether to move its content to `AGENTS.md` and leave `@AGENTS.md` in its place (recommended when another agent is used), or to keep editing `CLAUDE.md` only.
- Both: edit `AGENTS.md`; if `CLAUDE.md` does not import it, ask before adding `@AGENTS.md` to it.

## Project skills folder

Where project-local skills (such as the `verify-<app>` skill that `create-verification-skill` generates) live:

| Agent | Folder |
| --- | --- |
| Claude Code | `.claude/skills/` |
| Codex | `.agents/skills/` |
| Others | the project skills folder their documentation names; `.agents/skills/` when they read it |

Several agents with different folders: keep the skill in `.agents/skills/` and link it from each other folder (for Claude Code: `ln -s ../../.agents/skills/<skill> .claude/skills/<skill>`). On Windows without symbolic links in git, keep a copy and say so in `AGENTS.md`.

## Guardrails

The hard limits: an agent never reads secret files, never pushes to the main branch, never force-pushes.

- **Claude Code**: in `.claude/settings.json`, merge into `permissions.deny` without removing anything: `"Read(./.env)"`, `"Read(./.env.*)"`, `"Bash(git push origin <main>)"`, `"Bash(git push --force *)"`, `"Bash(git push -f *)"`; and `"Read(./.env.example)"` into `permissions.allow` if the file exists.
- **Codex**: keep its sandbox on (`workspace-write`) and its approval policy asking before commands it does not trust. If the installed Codex supports command rules (see its documentation), forbid the same pushes there. Rely on main branch protection for the rest.
- **GitHub Copilot and others**: use their command or tool approval settings if they have them; otherwise rely on main branch protection.

Main branch protection on the git host is the guardrail every agent shares: offer it whatever the agents.

## Stop gate

`hooks/before-stop.sh` (in the plugin) runs the check command before an agent stops with work that is not on the main branch yet, and sends the agent back while it fails.

- **Claude Code**: installed with the plugin; nothing to do.
- **Agents with a stop hook of their own**: point it at the script, `sh <plugin folder>/hooks/before-stop.sh`. It reads the hook's JSON from its input when there is one, and the current directory otherwise; exit code 2 means « keep working », with the reason on standard error.
- **Others**: no gate. The worker's own steps still run the check command before each report.

## Subagents

`build-feature` starts background agents. How each agent does it is in `build-feature/coding-agents.md`; there is nothing to set up, except:

- **Codex**: subagents need `multi_agent` enabled in `~/.codex/config.toml` (or under `$CODEX_HOME`): `[features]` then `multi_agent = true`. Offer to add it.
