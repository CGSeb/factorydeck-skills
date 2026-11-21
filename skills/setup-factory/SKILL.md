---
name: setup-factory
description: "Configure this repository for the factorydeck skills: git host (GitHub or GitLab), coding agents, spec format, labels, check command, merge policy and guardrails, written to docs/agents/. Run once before write-spec, check-spec or build-feature, and again when the workflow changes."
disable-model-invocation: true
---

# Set up the factory

Write `docs/agents/factory.md` and `docs/agents/git-host.md`, the configuration every other factorydeck skill reads, from what the repository already does. This is a prompt-driven setup, not a script: explore, present what you found, confirm with the person, then write.

## 1. Explore

Read what exists; assume nothing:

- `git remote -v`: the git host. A `github.com` remote is GitHub; `gitlab.com` or a self-hosted GitLab is GitLab. Check that its CLI is installed and logged in: `gh auth status` or `glab auth status` (in WSL with only the Windows CLI, `gh.exe` or `glab.exe`). No remote: ask for the repository and wire it (`git remote add origin <url>`).
- `docs/agents/factory.md` and `docs/agents/git-host.md`: an earlier run. Start from their values and change only what the person changes.
- `AGENTS.md`, `CLAUDE.md`, `README.md`, `CONTRIBUTING.md`: the languages used, the commit convention, the definition of done.
- The coding agents in use: `.claude/`, `.codex/`, `.github/copilot-instructions.md`, `.cursor/`, `.gemini/`, `.agents/`, and what the instructions files mention.
- The check command: package scripts, `Makefile`, `justfile`, CI config (`.github/workflows/`, `.gitlab-ci.yml`). Pick the one command that runs format, lint, types and tests together. None: propose the sequence CI runs.
- Existing specs or design docs (`docs/`, `specs/`, `rfcs/`, ADRs): their folder, file names, headings and status lines. Keep that format rather than imposing the template's.
- Labels (**List labels** in the git host file you are about to pick). Reuse labels that already play a role.
- A verification skill (`verify-*` in a skills folder).
- Lint, type, test, formatter and CI configs: they become protected paths.

## 2. Present and ask

Summarise what you found, then go through these sections in order, one section per question, recommended answer first so the person can accept it in a word. Skip a section the exploration settled beyond doubt. Ask in the person's language.

- **Git host**: GitHub or GitLab, recommended from the remote. Something else: say these skills support GitHub and GitLab, and stop.
- **Agents**: which coding agents work on this repository (Claude Code, Codex, GitHub Copilot, others). It decides the instructions file, the skills folder and the guardrails ([coding-agents.md](coding-agents.md)). Then the model of each role, among the models the person's agents and plans offer (ask; never assume a provider): recommend the most capable for spec checks and reviews, a strong one for workers, the cheapest that can follow a checklist for shippers, and `session default` when the person does not want to choose.
- **People**: the language for issue comments, questions and pull request bodies, and who to hand work to.
- **Checks**: the check command, and the services it needs (a `docker-compose.yml`, a database in the CI config): propose a services check that fails fast when they are down (`docker info` then the compose health check, for example) and the start command, or none. Offer the stop gate (on by default; see [coding-agents.md](coding-agents.md) for which agents it reaches). No verification skill: offer `/create-verification-skill` for later.
- **Specs**: the folder and the format. A repository with its own spec format keeps it: fill the table with its strings.
- **Issues**: the labels (defaults unless the repository already has its own), and how dependencies are recorded: GitLab blocking links need Premium or Ultimate; without them, the spec's depends-on line is the record.
- **Build**: parallel workers, branch and title conventions, auto-merge (on: the orchestrator merges a pull request whose gates pass and whose serenity score reaches the threshold; off: every pull request goes to the person).
- **Protected paths** and **rules for the reviewer**: propose them from what you read; the person adds the rules no tool enforces.

## 3. Write

Show the person both files complete before writing them; let them edit. Then:

1. `docs/agents/git-host.md`: copy [git-host-github.md](git-host-github.md) or [git-host-gitlab.md](git-host-gitlab.md), fill the repository and the CLI's name, and **check every command against the installed CLI**: run `<cli> <command> --help` for each one and fix any flag it does not have. CLIs change; a wrong flag here breaks every build. Run the read-only ones for real (**List labels**, **List the queue**).
2. `docs/agents/factory.md`: from [factory-template.md](factory-template.md), with no placeholder left. A section with nothing to say keeps its heading and says « None ».
3. Create the missing labels (**Create a label**).
4. The instructions file, the project skills folder, the guardrails, the stop gate and the subagent settings for each agent in use: follow [coding-agents.md](coding-agents.md).
5. Add this pointer to the instructions file:

   ```markdown
   ## Agent workflow

   Specs, labels, checks, git host commands and merge policy for agents: `docs/agents/factory.md`.
   ```

6. Main branch protection is the real merge gate, because a rule in prose can be argued with and a platform setting cannot. Offer **Protect the main branch**. Refused or not available: write it in the « Build » section, so the person knows the gate is prose only.

Done when neither file has a placeholder, every command in `docs/agents/git-host.md` matches the installed CLI's help, every label exists on the git host, and the check command passes on the main branch (run it once). Tell the person what was written, and that `/write-spec` starts the first spec.
