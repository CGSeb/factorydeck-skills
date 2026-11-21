---
name: build-feature
description: "Build features from their GitHub issues with a team of agents. Takes every issue of the queue that can be built now, starts one background builder per issue in its own worktree, reviews each branch independently before it is pushed, scores how safe it is to merge, and merges it when the gates and the score allow. Use when asked to build a feature, to take the next issues, or to work through the queue."
---

# Build features

You are the **orchestrator**. You never write feature code: you plan, start one worker per issue, have what they deliver reviewed, score it and merge it or hand it to a person. Workers follow [worker.md](worker.md); reviewers follow [reviewer.md](reviewer.md); shippers, on the cheapest model, follow [shipper.md](shipper.md); the gates and the score are in [serenity.md](serenity.md).

`docs/agents/factory.md` gives the repository, the labels, the check command, the verification skill, the conventions and the merge policy. It should exist; if not, tell the person to run `/setup-factory` and stop. Below, `gh` is the GitHub CLI it names, `<repo>` its repository, `<main>` its main branch, and a label in angle brackets (`<ready>`) the label of that role. Stay on an up-to-date `<main>` in the main checkout, and never edit files there.

Pass these paths to every agent you start: `<skill dir>` is the folder of this file, so they can read their role file.

## 1. Plan the batch

First clean up merged work (step 1a). If the person named issues, take those. Otherwise list the queue:

```bash
gh issue list --repo <repo> --label <spec> --label <ready> --state open --json number,title --jq 'sort_by(.title)'
```

An issue is **buildable** when none of its blockers is open:

```bash
gh api repos/<repo>/issues/<issue>/dependencies/blocked_by --jq '[.[] | select(.state == "open") | .number]'
```

A blocker is open until its pull request is merged: an issue whose blocker is being built in this batch waits for that merge. Read the depends-on line of each spec too; a dependency there that GitHub does not record counts the same, and tell the person it is missing.

Take the buildable issues in title order, **at most the parallel workers** of `docs/agents/factory.md` at a time. Claim each at once:

```bash
gh issue edit <issue> --repo <repo> --remove-label <ready> --add-label <working>
```

Tell the person the plan in a short table: the issues started, the ones waiting (and on what), and the ones left for later by the cap. Nothing buildable: say why and stop.

## 1a. Clean up merged work

Before planning, and after each merge, remove what merged pull requests left. A person may have merged one handed to them since the last batch. For each agent worktree (`git worktree list`):

```bash
gh pr list --repo <repo> --head <branch> --state merged --json number --jq length
```

- Not merged: keep it, it may get a follow-up.
- Merged and `git -C <path> status --short` empty: `git worktree remove <path>`, then `git branch -D <branch>`.
- Merged but with changes: check that they hold nothing new. When `git -C <path> write-tree` names the tree of a commit of the branch (`git log --all --format='%H %T'`), they are a stale state already committed: `git worktree remove --force <path>` and delete the branch. Otherwise keep it and tell the person what it holds.

Then delete the local branches no worktree uses any more: the throwaway branches agents' worktrees were created on, and the branches of merged pull requests.

## 1b. Check each spec before building

A spec with its checked line was checked with the person: start its worker. Otherwise check it first, on the most capable model whatever model the worker uses, so that the questions do not depend on the builder's model: one `Agent` per issue, all in the same message, `run_in_background: true`, `description: "Check spec #<issue>"`, and this prompt:

> Check the spec `<spec path>`, issue #<issue>. Run the `check-spec` skill on it in its « Before a build » mode: the person is not there.

- `open: none`: start the worker (step 2).
- Questions posted: the issue now waits for the person. Tell the person which questions wait, and take the next buildable issue if any. The issue returns to the queue when the person puts the ready label back.

## 2. Start the workers

One `Agent` call per issue, all in the same message: `isolation: "worktree"`, `run_in_background: true`, `description: "Build #<issue>"`, and this prompt:

> You are a build-feature worker. Build GitHub issue #<issue> (« <title> ») of `<repo>`, spec `<spec path>`, on branch `<branch name from the convention>`. Read `<skill dir>/worker.md` and follow it exactly. The issue is already claimed. Finish with the report it describes.

Keep each worker's id with its issue: you will send it review findings, CI failures and rebase conflicts with `SendMessage`. While workers run, do not poll them; you are notified when one reports.

A worker's context grows to hundreds of thousands of tokens, and every call it makes re-reads it. Resume a worker only for work that needs code; everything mechanical (rebase without conflict, push, pull request, labels, CI watch) goes to a fresh **shipper** (step 4b).

## 3. When a worker reports

- `needs-spec`: while building, the worker found a product choice the check missed. It asked on the issue and handed it to the person. Tell the person which questions wait, keep its worktree for the follow-up, then start the next buildable issue if any.
- `blocked`: the worker has labelled and commented the issue. Tell the person, then start the next buildable issue if any.
- `reviewable`: its work is committed on its local branch, proven and checked, **not pushed**, with its pull request body in the file its report names. Review it (step 4), unless it only added the open findings after the last review: then ship it (step 4b).
- `fixed`: it fixed a CI failure or a failed check the shipper reported. Ship it again (step 4b), without a new review.

## 4. Independent review, before any push

The review runs locally, so CI only runs on work that passed it. Start a **fresh** reviewer, never the worker: `Agent` with `description: "Review #<issue>"` and this prompt:

> Review the local branch `<branch>` of `<repo>`, worktree `<worktree>`, which builds issue #<issue> (spec `<spec path>`). Read `<skill dir>/reviewer.md` and follow it exactly.

Give it nothing else: not the worker's report, not your reasoning. Note the branch's head commit (`git rev-parse <branch>`): it is the start of a second round.

- **No finding**: ship it (step 4b).
- **Findings**: send them to the worker, verbatim. It fixes what is right, explains what it rejects, reruns the checks, commits and reports `reviewable` again. Then start a new fresh reviewer. **At most 2 review rounds**.
- **A second round after `minor` findings only** reviews the fix alone: add to the reviewer's prompt « Second round, since `<head of the first review>`. The findings it answers: <the first round's findings, verbatim> ». After a `blocker` or `major` finding, the second round reviews the whole branch again.
- After the second round, send the findings still open to the worker: it adds them to its pull request body with its position on each, changes no code, and reports `reviewable`; then ship it. A `blocker` or `major` finding still open hands the pull request to the person (step 5, score 0). `minor` findings still open only cost points.

## 4b. Ship

Start a fresh shipper, never the worker: `Agent` with the cheapest capable model (`model: "haiku"` in Claude Code), `run_in_background: true`, `description: "Ship #<issue>"`, and this prompt:

> Ship the branch `<branch>` of `<repo>`, worktree `<worktree>`, for issue #<issue>. Task: <« push and open the pull request titled `<title>` » | « push and update pull request #<pr> » | « rebase, push and update pull request #<pr> »>. Read `<skill dir>/shipper.md` and follow it exactly.

The title follows the pull request title convention of `docs/agents/factory.md`, with the subject of the worker's main commit; with a squash merge, it becomes the commit message on `<main>`.

- `green`: score it (step 5). A check the shipper reran counts as flaky.
- `ci-failed` or `check-failed`: send the failed check and the log excerpt to the worker, verbatim. It reports `fixed`; ship again.
- `conflict`: send the conflicting files to the worker as a rebase conflict. It reports `reviewable`; review the resolution (one round, step 4), then ship with « push and update ».

## 5. Gates, score and merge

Follow [serenity.md](serenity.md): run every gate, score the pull request, write the breakdown, then merge it or hand it to the person. Merge one pull request at a time.

## 6. After a merge

1. `git pull --ff-only` in the main checkout.
2. Every other branch with a pull request is now behind `<main>`: start a shipper with « rebase, push and update » (step 4b). A conflict goes to the worker and gets one local review round on its resolution before the push. Then score the pull request again.
3. Clean up the merged worker (step 1a).
4. Plan again (step 1): issues unblocked by this merge can start now, within the cap.

## 7. Finish

When no worker is running and nothing is buildable, report a table: issue, pull request, score, outcome (merged, waiting for a person and why, waiting for its spec and the questions asked, blocked and why), and where each verification left its evidence. Name first what a person should look at.

If FactoryDeck tracks this repository, point the person to the batch's cost per issue and per role there.

## Rules

- Never weaken a test, a rule, a gate or the threshold to merge. They live in `docs/agents/factory.md` and in this skill; only a person changes them.
- A worker stuck or silent after its fix attempts is blocked: label it blocked and comment the issue if it did not.
- Two workers never share a branch or an issue. Two branches that both add a database migration: the second to merge rebases and regenerates its migration.
