---
name: fix-bug
description: "Fix bugs from their bug issues (GitHub or GitLab) with a team of agents: build-feature's twin, with a debugger in place of the worker. Takes the fixable bugs of the queue, oldest first, starts one background debugger per bug in its own git worktree that reproduces it with a failing test, traces its root cause and makes the smallest fix, then reviews, scores and merges each fix like build-feature, or hands it to the person with a clear question. Use when asked to fix a bug, to take the next bugs, or to work through the bug queue."
---

# Fix bugs

You are the **orchestrator** of `build-feature`, for bug issues. You never write code: you plan, start one debugger per bug, have each fix reviewed, score it and merge it or hand it to a person. Debuggers follow [debugger.md](debugger.md); reviewers of a fix follow [reviewer.md](reviewer.md), on top of `build-feature`'s. Everything else is `build-feature`'s, read from its folder beside this one: its [SKILL.md](../build-feature/SKILL.md) for every step this file does not replace, [reviewer.md](../build-feature/reviewer.md), [shipper.md](../build-feature/shipper.md), [serenity.md](../build-feature/serenity.md) with [gates.sh](../build-feature/gates.sh), and [coding-agents.md](../build-feature/coding-agents.md) for starting and talking to agents. Read `build-feature`'s SKILL.md first: where it says worker, read debugger; where it says spec, read bug report.

`docs/agents/factory.yml` gives the bug settings (`bugs`) beside everything `build-feature` reads. Without it, or with a `factory.yml` that has no `bugs` section, say what is missing, tell the person to run `/setup-factory`, and stop before claiming anything.

`<skill dir>` is the folder of this file and `<build dir>` the `build-feature` folder beside it (`<skill dir>/../build-feature`): give both to every agent you start. A bug's report is the body of its issue, whatever `specs.location` says, read with **Read an issue**. Its criterion is its expected section (`bugs.format.sections.expected`): what the fix must make true.

Give every agent a short description that names its role and its issue as `#<issue>`, and nothing else: `check-bug #<issue>`, `Debug #<issue>`, `Review #<issue>` (every round), `Ship #<issue>`.

## 0. Check the machine, 1a. Clean up merged work

As `build-feature` steps 0 and 1a.

## 1. Plan the batch

Clean up merged work first. If the person named bugs, take those; otherwise **List the queue** with `bugs.label` in place of the spec label: the open issues with `bugs.label` and the ready label.

A bug is **fixable** when none of its blockers is open, by the rule of `build-feature` step 1 (its blocking links and its depends-on line). Take the fixable bugs **oldest first** (lowest issue number), at most `build.parallel_workers` at a time. Claim each at once: **Move an issue's labels** from `<ready>` to `<working>`.

Tell the person the plan in a short table: the bugs started, the ones waiting (and on what), and the ones left for later by the cap. Nothing fixable: say why and stop.

## 1b. Check each bug report before fixing

A report whose body has the checked line (`specs.format.checked_line`) was checked with the person: start its debugger. Otherwise check it first: one background agent per bug, all started together, on `agents.models.spec_check`, with this prompt:

> Check the bug report, the body of issue #<issue>. Run the `check-bug` skill on it in its « Before a fix » mode: the person is not there.

- `open: none`: start the debugger (step 2).
- Questions posted: the bug now waits for the person. Tell the person which questions wait, and take the next fixable bug if any. It returns to the queue when the person puts the ready label back.

## 2. Start the debuggers

For each bug, create its worktree as in `build-feature` step 2, on a branch that follows `bugs.branch_name`, from an up-to-date `<main>`. A bug that comes back to the queue after a hand-over keeps the worktree and the branch of its last attempt: reuse them, after `git -C <worktree> rebase origin/<main>` (a conflict: remove nothing, and tell the person). Then start one background agent per bug, all together, on `agents.models.worker`, with this prompt:

> You are a fix-bug debugger. Fix bug issue #<issue> (« <title> »), bug report: the body of issue #<issue>, in the worktree `<worktree path>` on branch `<branch>`; work only there. Read `<skill dir>/debugger.md` and follow it exactly; it points to `<build dir>/worker.md` for the parts it shares. The issue is already claimed. Finish with the report it describes.

For a bug back after a hand-over, add: « An earlier attempt left its notes in the issue's comments and in your factory folder: read them first. »

## 3. When a debugger reports

As `build-feature` step 3, with one difference: `needs-spec` comes with a `reason`.

- `cannot-reproduce`: the debugger could not make a test fail and asked the reporter for steps, data or a version.
- `intended-behaviour`: the observed behaviour is what a spec or the product context asks for; the debugger quoted the sentence.
- `null`: a product choice the report leaves open, as for a worker.

Tell the person the reason and the questions that wait, keep the worktree, then start the next fixable bug if any.

## 4. Review, ship, score and merge

As `build-feature` steps 4 to 7, with these prompts and rules:

- **Review**: a fresh reviewer, on `agents.models.reviewer`, with this prompt:

  > Review the local branch `<branch>`, worktree `<worktree>`, which fixes bug issue #<issue>. The spec is the bug report, the body of issue #<issue>: its expected section is the only acceptance criterion, and the reproduction test the debugger kept must assert it. Read `<skill dir>/reviewer.md` and follow it exactly; it points to `<build dir>/reviewer.md` for the parts it shares.

  Findings go to the debugger, with the same rounds and rules. A `blocker` finding on reproduction means the debugger rewrites the test. Every round runs « Fails on main » of [reviewer.md](reviewer.md) again, later ones included.
- **Ship**: a fresh shipper, on `agents.models.shipper`, told to read `<build dir>/shipper.md`. The pull request title follows `bugs.pull_request_title`, with the subject of the debugger's main commit.
- **Gates**: [serenity.md](../build-feature/serenity.md), with two gates replaced and two added for a fix, the last two read from the last review's report:

  | Gate | Passes when |
  | --- | --- |
  | One issue | the pull request closes exactly one issue, and it carries `bugs.label` |
  | No spec | the diff changes no spec file (`gates.sh` lists none under « specs touched » with `specs.location: repository`), and the body of the issue it closes is not ticked: a bug report has no criteria |
  | Reproduced | `reproduction.result` is `failed-on-assertion` |
  | Root cause | the pull request body has a `## Root cause` section with content, and `root_cause.verdict` is `confirmed` |

  A failed gate refuses the merge and hands the pull request to the person, like every gate of serenity.md, with the gate's name and the reviewer's reason (the result and its excerpt, or the verdict and its `why`) among the reasons. Every other gate and every line of the score stays as in serenity.md.
- **Serenity report**: the breakdown of serenity.md, with two more lines right after its `Review:` line, each on its own line:

  ```markdown
  Gates: all passed. Review: 1 round, confidence high.
  Root cause: <root_cause.sentence>
  Reproduced: failed on main
  ```

  - `Root cause: ` then the last review's `root_cause.sentence` on one line (line breaks become spaces), at most 200 characters: a longer one is cut at 199 and ends with `…`. With no sentence, `Root cause: none`.
  - `Reproduced: ` then, from `reproduction.result`: `failed on main` (`failed-on-assertion`), `passed on main` (`passed`), `did not run on main` (`failed-to-run`) or `no test` (`no-test`).

  These words are fixed: FactoryDeck matches `Root cause:`, `Reproduced:` and the four values exactly. Only `fix-bug` writes them; every other line keeps serenity.md's format, and `build-feature`'s reports do not change.
- **Plan again** (`build-feature` step 6) means step 1 of this file.
- **Finish** (`build-feature` step 7): the table names, for each bug, its pull request, score and outcome, or the reason and the questions it waits on, and its factory folder.

## Rules

- `fix-bug` takes only issues with `bugs.label`, `build-feature` only those with the spec label, and `bugs.label` never equals a label of `issues.labels`: they never take the same issue. Both may run at the same time, each within its own `build.parallel_workers` cap.
- The rules of `build-feature` apply: never weaken a test, a rule, a gate or the threshold to merge.
- The debugger never edits the issue body, and nobody closes a bug except the merge of its fix.
- Without background agents, run the roles yourself as « Without background agents » of [coding-agents.md](../build-feature/coding-agents.md) says, with the role `debugger` in place of `builder`: `Work item: #<issue> (debugger)` after debugging or reworking a fix.
