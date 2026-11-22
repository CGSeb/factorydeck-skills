---
name: build-feature
description: "Build features from their issues (GitHub or GitLab) with a team of agents. Takes every issue of the queue that can be built now, starts one background builder per issue in its own git worktree, reviews each branch independently before it is pushed, scores how safe it is to merge, and merges it when the gates and the score allow. Use when asked to build a feature, to take the next issues, or to work through the queue."
---

# Build features

You are the **orchestrator**. You never write feature code: you plan, start one worker per issue, have what they deliver reviewed, score it and merge it or hand it to a person. Workers follow [worker.md](worker.md); reviewers follow [reviewer.md](reviewer.md); shippers follow [shipper.md](shipper.md); each role runs on its model of `docs/agents/factory.yml`; the gates and the score are in [serenity.md](serenity.md). How to start and talk to those agents in your coding agent is in [coding-agents.md](coding-agents.md).

`docs/agents/factory.yml` gives the labels (`issues.labels`), the checks and services (`checks`), the models of each role (`agents.models`), the conventions and the merge policy (`build`); operations in **bold** are commands of `docs/agents/git-host.md` (on GitLab, a « pull request » is a merge request). They should exist; if not, tell the person to run `/setup-factory` and stop. Below, `<main>` is the main branch and a label in angle brackets (`<ready>`) the label of that role. Stay on an up-to-date `<main>` in the main checkout, and never edit files there.

`<skill dir>` is the folder of this file: give it to every agent you start, so it can read its role file.

Give every agent you start a short description that names its role and its issue as `#<issue>`, and nothing else: `check-spec #<issue>`, `Worker for #<issue>`, `Review #<issue>` (every round), `Ship #<issue>`. Coding agents record that description with the agent's transcript; FactoryDeck reads its role and its issue there, and the branch an agent records is the one it was started from (`<main>`), not its worktree's.

## 0. Check the machine

When `checks.services.check` in `docs/agents/factory.yml` is not `none`, run it before anything else, even before cleaning up:

- It fails: **stop here**. Claim nothing, start no agent, and tell the person in one sentence what to start by hand (`checks.services.manual_start`) and to say when it runs. Never start it yourself. When the person confirms, run this step again.
- It succeeds: run `checks.services.start` in the main checkout, unless it is `none`, (the only place it runs), then go on.

A worker that reports `blocked` with a `services-down` reason is not a product block: tell the person what to restart, run this step again when they confirm, then write to that worker to resume. Start no other worker in the meantime.

## 1. Plan the batch

First clean up merged work (step 1a). If the person named issues, take those. Otherwise **List the queue**.

An issue is **buildable** when none of its blockers is open: **Open blockers** for each, and read the depends-on line of each spec too. A blocker is open until its pull request is merged: an issue whose blocker is being built in this batch waits for that merge. A dependency in the spec that the git host does not record counts the same; when the git host records blocking links, tell the person it is missing.

Take the buildable issues in title order, **at most `build.parallel_workers`** at a time. Claim each at once: **Move an issue's labels** from `<ready>` to `<working>`.

Tell the person the plan in a short table: the issues started, the ones waiting (and on what), and the ones left for later by the cap. Nothing buildable: say why and stop.

## 1a. Clean up merged work

Before planning, and after each merge, remove what merged pull requests left. A person may have merged one handed to them since the last batch. For each worktree of `git worktree list` other than the main checkout, **Merged pull requests of a branch**:

- Not merged: keep it, it may get a follow-up.
- Merged and `git -C <path> status --short` empty: `git worktree remove <path>`, then `git branch -D <branch>`.
- Merged but with changes: check that they hold nothing new. When `git -C <path> write-tree` names the tree of a commit of the branch (`git log --all --format='%H %T'`), they are a stale state already committed: `git worktree remove --force <path>` and delete the branch. Otherwise keep it and tell the person what it holds.

Then delete the local branches of merged pull requests that no worktree uses any more.

Leave each branch's factory folder (`factory/<branch>` in the repository's shared git directory, `git rev-parse --path-format=absolute --git-common-dir`): it holds the evidence, outside any worktree and never committed. Step 7 names it. Delete a factory folder once its branch is gone from `git branch` and no file in it changed for 30 days: `find <folder> -mtime -30 | head -1` prints nothing.

## 1b. Check each spec before building

A spec with its checked line was checked with the person: start its worker. Otherwise check it first, on the model for spec checks, so that the questions do not depend on the builder's model: one background agent per issue, all started together, with this prompt:

> Check the spec `<spec path>`, issue #<issue>. Run the `check-spec` skill on it in its « Before a build » mode: the person is not there.

- `open: none`: start the worker (step 2).
- Questions posted: the issue now waits for the person. Tell the person which questions wait, and take the next buildable issue if any. The issue returns to the queue when the person puts the ready label back.

## 2. Start the workers

For each issue, create its worktree yourself, on its branch, from an up-to-date `<main>`, outside the main checkout (a sibling folder, or one git ignores):

```bash
git fetch origin <main> && git worktree add -b <branch> <worktree path> origin/<main>
```

The branch name follows `build.branch_name`. Then start one background agent per issue, all together, on the model for workers, with this prompt:

> You are a build-feature worker. Build issue #<issue> (« <title> »), spec `<spec path>`, in the worktree `<worktree path>` on branch `<branch>`; work only there. Read `<skill dir>/worker.md` and follow it exactly. The issue is already claimed. Finish with the report it describes.

Keep each worker's id with its issue, its worktree and its branch: you will send it review findings, CI failures and rebase conflicts. While workers run, do not poll them; wait for their reports.

A worker's context grows to hundreds of thousands of tokens, and every call it makes re-reads it. Write to a worker only for work that needs code; everything mechanical (rebase without conflict, push, pull request, labels, CI watch) goes to a fresh **shipper** (step 4b).

## 3. When a worker reports

- `needs-spec`: while building, the worker found a product choice the check missed. It asked on the issue and handed it to the person. Tell the person which questions wait, keep its worktree for the follow-up, then start the next buildable issue if any.
- `blocked` with a `services-down` reason: step 0.
- `blocked`: the worker has labelled and commented the issue. Tell the person, then start the next buildable issue if any.
- `reviewable`: its work is committed on its local branch, proven and checked, **not pushed**, with its pull request body in the file its report names. Review it (step 4), unless it only added the open findings after the last review: then ship it (step 4b).
- `fixed`: it fixed a CI failure or a failed check the shipper reported. Ship it again (step 4b), without a new review.

## 4. Independent review, before any push

The review runs locally, so CI only runs on work that passed it. Start a **fresh** reviewer, never the worker, on the model for reviewers, with this prompt:

> Review the local branch `<branch>`, worktree `<worktree>`, which builds issue #<issue> (spec `<spec path>`). Read `<skill dir>/reviewer.md` and follow it exactly.

Give it nothing else: not the worker's report, not your reasoning. Note the branch's head commit (`git rev-parse <branch>`): it is the start of a second round.

- **No finding**: ship it (step 4b).
- **Findings**: send them to the worker, verbatim. It fixes what is right, explains what it rejects, reruns the checks, commits and reports `reviewable` again. Then start a new fresh reviewer. **At most 2 review rounds**.
- **A second round after `minor` findings only** reviews the fix alone: add to the reviewer's prompt « Second round, since `<head of the first review>`. The findings it answers: <the first round's findings, verbatim> ». After a `blocker` or `major` finding, the second round reviews the whole branch again.
- After the second round, send the findings still open to the worker: it adds them to its pull request body with its position on each, changes no code, and reports `reviewable`; then ship it. A `blocker` or `major` finding still open hands the pull request to the person (step 5, score 0). `minor` findings still open only cost points.

## 4b. Ship

Start a fresh shipper, never the worker, on the model for shippers, in the background, with this prompt:

> Ship the branch `<branch>`, worktree `<worktree>`, for issue #<issue>. Task: <« push and open the pull request titled `<title>` » | « push and update pull request #<pr> » | « rebase, push and update pull request #<pr> »>. Read `<skill dir>/shipper.md` and follow it exactly.

The title follows `build.pull_request_title`, with the subject of the worker's main commit; with a squash merge, it becomes the commit message on `<main>`.

- `green`: score it (step 5). A check the shipper reran counts as flaky.
- `ci-failed` or `check-failed`: send the failed check and the log excerpt to the worker, verbatim. It reports `fixed`; ship again.
- `conflict`: send the conflicting files to the worker as a rebase conflict. It reports `reviewable`; review the resolution (one round, step 4), then ship with « push and update ».

## 5. Gates, score and merge

Follow [serenity.md](serenity.md): run every gate, score the pull request, write the breakdown, then merge it or hand it to the person. Merge one pull request at a time.

## 5b. Wait for a person's merge

When a pull request goes to the person (step 5) and an issue of the queue is blocked by it, the batch can go on only after the person merges it. Watch it rather than stop:

- One watch for every pull request handed over, started with step 5's hand-over: every 20 seconds, **Pull request facts** for each, until one is merged or closed. How to watch without polling yourself: « Wait for an external change » in [coding-agents.md](coding-agents.md).
- Merged: step 0 again (a service may have stopped meanwhile), then step 6.
- Closed without merge: its blocked issues stay blocked; tell the person.
- No issue waits on a handed-over pull request any more, or 24 hours passed: stop the watch, and say in step 7 which pull requests still wait.

## 6. After a merge

1. `git pull --ff-only` in the main checkout.
2. Every other branch with a pull request is now behind `<main>`: start a shipper with « rebase, push and update » (step 4b). A conflict goes to the worker and gets one local review round on its resolution before the push. Then score the pull request again.
3. Clean up the merged worker (step 1a).
4. Plan again (step 1): issues unblocked by this merge can start now, within the cap.

## 7. Finish

When no worker or watch is running and nothing is buildable, report a table: issue, pull request, score, outcome (merged, waiting for a person and why, waiting for its spec and the questions asked, blocked and why), and the factory folder of each branch, which holds its evidence and its pull request body. Name first what a person should look at.

If FactoryDeck tracks this repository, point the person to the batch's cost per issue and per role there.

## Rules

- Never weaken a test, a rule, a gate or the threshold to merge. They live in `docs/agents/factory.yml` and in this skill; only a person changes them.
- A worker stuck or silent after its fix attempts is blocked: label it blocked and comment the issue if it did not.
- Two workers never share a branch, a worktree or an issue. Two branches that both add a database migration: the second to merge rebases and regenerates its migration.
- The person wants to try a branch: run it yourself, in the background, from its worktree, the way `docs/agents/factory-notes.md` proves work in the real app, and give them the address. A command you hand them starts with `cd <worktree> &&` in the same block: the main checkout runs `<main>`, not the branch.
