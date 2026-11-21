---
name: setup-factory
description: "Configure this repository for the factorydeck-skills: GitHub repository, spec format, labels, check command, merge policy and guardrails, written to docs/agents/factory.md. Run once before write-spec, check-spec or build-feature, and again when the workflow changes."
disable-model-invocation: true
---

# Set up the factory

Write `docs/agents/factory.md`, the configuration every other factorydeck skill reads, from what the repository already does. This is a prompt-driven setup, not a script: explore, present what you found, confirm with the person, then write.

## 1. Explore

Read what exists; assume nothing:

- `git remote -v`: the GitHub repository. Check that `gh repo view` works from here; in WSL with only the Windows CLI, it is `gh.exe`. No GitHub remote: ask for the repository and wire it (`git remote add origin <url>`). Done when `gh repo view` prints it.
- `docs/agents/factory.md`: an earlier run. Start from its values and change only what the person changes.
- `CLAUDE.md`, `AGENTS.md`, `README.md`, `CONTRIBUTING.md`: the languages used, the commit convention, the definition of done.
- The check command: package scripts, `Makefile`, `justfile`, CI workflows in `.github/workflows`. Pick the one command that runs format, lint, types and tests together. None: propose the sequence CI runs.
- Existing specs or design docs (`docs/`, `specs/`, `rfcs/`, ADRs): their folder, file names, headings and status lines. Keep that format rather than imposing the template's.
- Labels: `gh label list --limit 200`. Reuse labels that already play a role.
- A verification skill (`.claude/skills/verify-*`).
- Lint, type, test and formatter configs: they become protected paths.

## 2. Present and ask

Summarise what you found, then go through the sections of [factory-template.md](factory-template.md) in order, one section per question, recommended answer first so the person can accept it in a word. Skip a section the exploration settled beyond doubt. Ask in the person's language.

- **People**: the language for issue comments, questions and pull request bodies.
- **Checks**: the check command. Offer the stop gate (on by default): before an agent stops with uncommitted or unpushed work, the plugin's hook runs the check command and sends the agent back while it fails. No verification skill: offer `/create-verification-skill` for later.
- **Specs**: the folder and the format. A repository with its own spec format keeps it: fill the table with its strings.
- **Issues**: the labels. Defaults unless the repository already has its own.
- **Build**: parallel workers, branch and title conventions, auto-merge (on: the orchestrator merges a pull request whose gates pass and whose serenity score reaches the threshold; off: every pull request goes to the person).
- **Protected paths** and **rules for the reviewer**: propose them from what you read; the person adds the rules no tool enforces.

## 3. Write

Show the person the complete `docs/agents/factory.md` before writing it; let them edit it. Then:

1. Write `docs/agents/factory.md` from the template, with no placeholder left. A section with nothing to say keeps its heading and says « None ».
2. Create the missing labels: `gh label create <label> --description "<role>"`.
3. Add the guardrails to `.claude/settings.json` (create it, or merge into the existing `permissions.deny` list without removing anything):

   ```json
   {
     "permissions": {
       "deny": [
         "Read(./.env)",
         "Read(./.env.*)",
         "Bash(git push origin <main branch>)",
         "Bash(git push --force *)",
         "Bash(git push -f *)"
       ]
     }
   }
   ```

   Keep `Read(./.env.example)` readable if the repository has one: add `"Read(./.env.example)"` to `permissions.allow`.

4. Add a pointer to whichever of `CLAUDE.md` or `AGENTS.md` exists (ask which to create when neither does; never create the second one):

   ```markdown
   ## Agent workflow

   Specs, labels, checks and merge policy for agents: `docs/agents/factory.md`.
   ```

5. Branch protection is the real merge gate, because a rule in prose can be argued with and a platform setting cannot. Offer to require the CI checks and an up-to-date branch on the main branch. It needs admin rights, and private repositories need a paid plan:

   ```bash
   gh api -X PUT repos/<owner>/<repo>/branches/<main branch>/protection --input <file>
   ```

   with `{"required_status_checks": {"strict": true, "contexts": [<check names from the last CI run>]}, "enforce_admins": false, "required_pull_request_reviews": null, "restrictions": null}`. Refused or declined: say so in the « Build » section, so the person knows the gate is prose only.

Done when `docs/agents/factory.md` has no placeholder, every label in it exists on GitHub, and the check command it names passes on the main branch (run it once). Tell the person what was written, and that `/write-spec` starts the first spec.
