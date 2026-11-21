---
name: create-verification-skill
description: "Generate a project-local verification skill that drives your app the way a user does, in any language, framework or platform, with a feature map. Use for /create-verification-skill, \"make a verify skill for this repo\", or when a project has no scripted way to prove UI, CLI or service behaviour."
disable-model-invocation: true
---

# Create a verification skill

Adapted from Lauren Tan's pstack (MIT). See `CREDITS.md`.

Every serious project needs a scripted way to drive the real app and prove behaviour: launch it, exercise a feature the way a user would, and capture evidence. This skill generates that as a project-local skill, `.claude/skills/verify-<app>/`, tailored to the repository. You write the output for the next agent, not for a human: it will be read cold, mid-task, by an agent that has never seen the app. `build-feature` workers use it to prove each criterion.

## 1. Interview the repo, not the user

Answer these from the codebase and only ask the person what you cannot observe:

- **Surface:** what does a user actually touch? A web UI, a CLI or TUI, a desktop app, an API, a mobile app, a library? A repo can have several; pick the primary one and note the rest.
- **Run:** how does the app start locally? Prefer the repo's own documented dev command (package scripts, Makefile, README quickstart). Note ports, environment variables, seed data, auth.
- **Drive:** how can an agent interact with it programmatically? Existing harnesses first: Playwright or Cypress specs, expect scripts, PTY helpers, curl-able endpoints, a debug port, a browser tool the agent already has. Only then pick a generic recipe: a browser over CDP for web and Electron, a tmux or PTY session for CLI and TUI, plain HTTP for services.
- **Observe:** what evidence can be captured? Screenshots, accessibility snapshots, terminal transcripts, response bodies, logs, exit codes, database state.
- **Isolate:** can two instances run side by side (ports, data directories, profiles)? `build-feature` runs several workers at once, each in its own worktree. If instances cannot be isolated, say so in the generated skill: refusing to double-drive a shared instance beats corrupting someone's session.

If the checkout does not build or start as is, fix that first (or report it precisely) before generating; a skill written against a broken base teaches wrong steps. When an irrelevant missing asset blocks startup (a static folder the API never serves, a sample config), the generated skill may create it, clearly marked as verification scaffolding, and remove it in cleanup.

## 2. Generate the skill

Write `.claude/skills/verify-<app>/SKILL.md` with YAML frontmatter (`name: verify-<app>` and a `description` that names the app, the surface, and when to reach for it; without frontmatter the skill never registers) and these sections, each grounded in what the interview found, with no placeholder left:

- **Launch:** the exact command that starts the app for verification, and how to tell it is ready (a log line, a prompt). Launch must reach a usable state from an empty data directory, including migrations and seed data. Ready means usable, not just that a process answers: a database health check can pass while its init scripts are still running. Include teardown. For a short-lived CLI or TUI there is no server to keep alive: launch means build the binary (or install dependencies) once, then start each drive in its own isolated PTY or tmux session.
- **Doctor:** one read-only check that answers « is this instance worth driving? »: process up, right version or build, port owned by this run, auth valid. An agent runs it first whenever anything looks off.
- **Drive:** the harness recipe with real selectors and commands from this repo, not examples. Prefer stable handles (accessible roles and names, data attributes, prompt strings, route paths) over coordinates and tab order.
- **Evidence:** what to capture for a proof and where it goes (a folder git ignores, named in the skill). State the proof standards: exercise the real user path, not internal setters or test-only endpoints; capture the action and the resulting state, not just the final screen; verify side effects (files written, rows inserted, messages sent) alongside what is visible; mocks only where a production boundary already isolates the external system. When the safe path is a dry run or test mode, verify what it actually skips by observing (files, network, git refs) rather than trusting its name.
- **Cleanup:** how to tear down instances the run created. Never kill by process name; kill what you started. Cleanup removes instances and scratch state, never the evidence: proof artifacts survive the teardown, in the location the skill names.
- **Helpers:** keep them few and dependency-light: a shell script using what the project already needs beats a new toolchain. Any script the skill ships is executable and its invocation is shown in the skill body. A helper the reader has to reverse-engineer is not a helper.

## 3. Seed the feature map

Create `.claude/skills/verify-<app>/features/README.md` plus one file per user-facing feature you can identify (aim for the top 3 to 5 to start, from routes, commands, menus or docs). Follow the shape in [references/feature-map-example/](references/feature-map-example/): a README index and one file per feature. Each file answers, from the user's point of view: what the feature is, how to reach it, how to drive it with the harness, and what observable end state proves it works. The four H2s are `Sub-features`, `How to get to it (user POV)`, `Driving it with <harness>` and `Gotchas`.

If the seed data lacks a precondition that a journey needs, the journey reports a failure and the reason goes in that feature's `Gotchas`. Never weaken the journey to make it pass. The map is the repository's maintained verification source; a proof that drives one convenient entry point is incomplete when the map lists others.

## 4. Prove the generated skill before handing it over

Run its own instructions end to end once: launch, doctor, drive one mapped feature (one is enough; the map exists so later runs can cover the rest), capture evidence, clean up. After cleanup, confirm the evidence still exists at the named location: a cleanup that eats the proof fails this step. Fix what fails, and run the generated cleanup after every failed iteration too, so broken attempts do not strand processes and ports. A generated skill that was never executed is a draft, not a deliverable.

If you proved it in a stand-in for the real target (a container in place of a fresh machine, a local stack in place of a remote one), list every setup step the stand-in did that the target will not. Those steps stay unverified until a run on the real target covers them.

## 5. Wire it and offer the maintenance loop

Set `Verification skill: verify-<app>` in `docs/agents/factory.md` when it exists, so `build-feature` workers use it. Point the person at `/maintain-verification-skill` for keeping the map honest as the app changes; suggest a cadence only if they ask.
