# Guardrails

A rule written in a skill can be argued with; a platform setting cannot. So the hard limits live in the platforms:

- **Main branch protection** on the git host: CI must pass and the branch must be up to date before any merge. GitLab offers it on every tier; GitHub on public repositories, or private ones on paid plans.
- **Agent permissions**: `setup-factory` denies Claude Code reading `.env` files, pushing to the main branch and force-pushing, and sets the closest equivalent for the other agents.
- **The merge gate** in `build-feature`: a pull request that touches the rules agents are graded by, adds a lint or test suppression, or edits a migration always goes to a person.

## Stop gate

`hooks/before-stop.sh` runs your check command before an agent stops with work that is not on the main branch yet, and sends it back while the check fails (three times at most). It does nothing in a repository without `docs/agents/factory.yml`, and `checks.stop_gate: false` there turns it off. The Claude Code plugin installs it; any other agent with a stop hook can call `sh <plugin folder>/hooks/before-stop.sh` (exit code 2 means « keep working »).

The settings these read live in `docs/agents/factory.yml`: see [Configuration](configuration.md).
