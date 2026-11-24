---
name: setup-factory
description: "Configure this repository for the factorydeck skills: git host (GitHub or GitLab), coding agents, spec format, labels, check command, merge policy and guardrails, written to docs/agents/. Run once before write-spec, check-spec or build-feature, and again when the workflow changes."
disable-model-invocation: true
---

# Set up the factory

Write `docs/agents/factory.yml`, `docs/agents/factory-notes.md` and `docs/agents/git-host.md`, the configuration every other factorydeck skill reads, from what the repository already does. This is a prompt-driven setup, not a script: explore, present what you found, confirm with the person, then write.

## 1. Explore

Read what exists; assume nothing:

- `git remote -v`: the git host. A `github.com` remote is GitHub; `gitlab.com` or a self-hosted GitLab is GitLab. Check that its CLI is installed and logged in: `gh auth status` or `glab auth status` (in WSL with only the Windows CLI, `gh.exe` or `glab.exe`). No remote: ask for the repository and wire it (`git remote add origin <url>`).
- `docs/agents/factory.yml`, `docs/agents/factory-notes.md` and `docs/agents/git-host.md`: an earlier run. Start from their values and change only what the person changes. A `factory.yml` of `version: 1`: move `checks.notes`, `build.commit_notes`, `build.main_branch_protection_notes` and `reviewer_rules` to the sections of `factory-notes.md` (one bullet per reviewer rule), delete those keys and set `version: 2`. A `git-host.md` that lacks an operation of the template gets it, with its command checked as in step 3.1. A `docs/agents/factory.md` from a version before 0.4: carry its values into both files, then delete it.
- `AGENTS.md`, `CLAUDE.md`, `README.md`, `CONTRIBUTING.md`: the languages used, the commit convention, the definition of done.
- The coding agents in use: `.claude/`, `.codex/`, `.github/copilot-instructions.md`, `.cursor/`, `.gemini/`, `.agents/`, and what the instructions files mention.
- The check command: package scripts, `Makefile`, `justfile`, CI config (`.github/workflows/`, `.gitlab-ci.yml`). Pick the one command that runs format, lint, types and tests together. None: propose the sequence CI runs.
- Existing specs or design docs (`docs/`, `specs/`, `rfcs/`, ADRs): their folder, file names, headings and status lines. Keep that format rather than imposing the template's.
- Specs written in issues: **Read an issue** on up to 5 recent issues that look like specs (those of a spec label when one exists, otherwise recent issues with acceptance criteria or a user story), and note the headings and lines they share (`### Acceptance criteria`, `**Done when**`, `Depends on:`).
- Project-wide context: a product README or docs folder, links in them to a wiki or an external tool (Notion, Confluence, Google Docs), and whether the git host's wiki has pages.
- Labels (**List labels** in the git host file you are about to pick). Reuse labels that already play a role.
- A verification skill (`verify-*` in a skills folder).
- Lint, type, test, formatter and CI configs: they become protected paths.

## 2. Present and ask

Summarise what you found, then go through these sections in order, one section per question, recommended answer first so the person can accept it in a word. Skip a section the exploration settled beyond doubt. Ask in the person's language.

- **Git host**: GitHub or GitLab, recommended from the remote. Something else: say these skills support GitHub and GitLab, and stop.
- **Agents**: which coding agents work on this repository (Claude Code, Codex, GitHub Copilot, others). It decides the instructions file, the skills folder and the guardrails ([coding-agents.md](coding-agents.md)). Then the model of each role, among the models the person's agents and plans offer (ask; never assume a provider): recommend the most capable for spec checks and reviews, a strong one for workers, the cheapest that can follow a checklist for shippers, and `session-default` when the person does not want to choose.
- **People**: the language for issue comments, questions and pull request bodies, and who to hand work to.
- **Checks**: the check command, and the services it needs (a `docker-compose.yml`, a database in the CI config): propose a services check that fails fast when they are down (`docker info` then the compose health check, for example) and the start command, or none. Offer the stop gate (on by default; see [coding-agents.md](coding-agents.md) for which agents it reaches). No verification skill: offer `/create-verification-skill` for later.
- **Specs**: first where a feature spec lives (`specs.location`): files of the repository (recommended when a specs folder was found) or the issues themselves (recommended when the issues hold acceptance criteria and no specs folder exists). One location for the whole project. Then, for `repository`, the folder and the file name; for `issue`, both are `none`. Then the format: specs that already exist, in files or issues, keep theirs: fill `specs.format` with the strings they share; when they share none, propose the template's. With `issue`, the status line is not written in the body (labels and the issue's state carry the status), but `status_line` and `status_values` stay filled.
- **Product context** (`specs.product_context`): the project-wide context agents read when a task needs it: files of the repository (paths from the root; refuse `~` and absolute paths, which other machines lack), wiki pages, external links, or `none`. Read each source that is not a file once, where it is and the way a background agent would: **Read a wiki page** for a page of the git host's wiki, the agent's connector or fetch tool for an external page. One that fails: tell the person, and offer a copy in the repository that they keep up to date (list the copy instead) or to leave the source out. Write how each source is read under « Product context » in `factory-notes.md`. The product context never goes into the instructions file: it is loaded in every session and holds the rules for working on the code, while the context is read on demand, only the part a task touches.
- **Issues**: the labels (defaults unless the repository already has its own), and how dependencies are recorded: GitLab blocking links need Premium or Ultimate; without them, the spec's depends-on line is the record.
- **Build**: parallel workers; the commit convention, branch name and pull request title, taken from the repository (instructions files, a commit hook such as commitlint, lefthook or husky, `git log --format=%s -30`, `git branch -r`) and never imposed: a repository without one keeps plain subjects; auto-merge (on: the orchestrator merges a pull request whose gates pass and whose serenity score reaches the threshold; off: every pull request goes to the person).
- **Code comments** (`build.code_comments`): offer the three options, with the one the instructions files point to as the recommendation, `directives-only` when they say nothing: `directives-only` (tool directives only, no descriptive or documentation comment, no why), `documentation` (also documentation comments such as TSDoc or docstrings, and a rare why), `any` (the instructions files decide).
- **Protected paths** and **rules for the reviewer**: propose them from what you read; the person adds the rules no tool enforces.
- **Notes**: what a builder must know to run the checks and prove its work (narrower commands, a service to stub, a limit of the machine), and the full commit convention with an example per kind of change. They go in `docs/agents/factory-notes.md`, with the rules for the reviewer.

## 3. Write

Show the person the three files complete before writing them; let them edit. Then:

1. `docs/agents/git-host.md`: copy [git-host-github.md](git-host-github.md) or [git-host-gitlab.md](git-host-gitlab.md), fill the repository and the CLI's name, and **check every command against the installed CLI**: run `<cli> <command> --help` for each one and fix any flag it does not have. CLIs change; a wrong flag here breaks every build. Run the read-only ones for real (**List labels**, **List the queue**). When the CLI cannot read the repository from the clone (a Windows `gh.exe` or `glab.exe` under WSL fails with « dubious ownership » or « not a git repository »), add `--repo <owner>/<repo>` (`-R` for `glab`) to every command that does not already name it.
2. `docs/agents/factory.yml`: from [factory-template.yml](factory-template.yml), keeping its comments and its first line (the schema link), with no `<placeholder>` left. A setting with nothing to say is `none`, `""` or `[]`. Check it against [factory.schema.json](factory.schema.json) when a validator is at hand (an editor with the YAML language server, `check-jsonschema`); otherwise read it against the schema yourself. Keep to plain block YAML, one key per line: the stop gate reads it with a shell parser.
3. `docs/agents/factory-notes.md`: from [factory-notes-template.md](factory-notes-template.md), keeping its headings, with « None. » under a section with nothing to say.
4. Create the missing labels (**Create a label**).
5. The instructions file, the project skills folder, the guardrails, the stop gate and the subagent settings for each agent in use: follow [coding-agents.md](coding-agents.md).
6. Add this pointer to the instructions file:

   ```markdown
   ## Agent workflow

   Specs, labels, checks, models and merge policy for agents: `docs/agents/factory.yml`; notes on checks and commits, and the rules for the reviewer: `docs/agents/factory-notes.md`. Git host commands: `docs/agents/git-host.md`.
   ```

   This pointer is the only mention of specs and product context in the instructions file.

7. Main branch protection is the real merge gate, because a rule in prose can be argued with and a platform setting cannot. Offer **Protect the main branch**. Refused or not available: set `build.main_branch_protection` to false and say why under « Main branch protection » in `docs/agents/factory-notes.md`, so the person knows the gate is prose only.

Done when no file has a placeholder, every command in `docs/agents/git-host.md` matches the installed CLI's help, every label exists on the git host, and the check command passes on the main branch (run it once). Tell the person what was written, and that `/write-spec` starts the first spec.
