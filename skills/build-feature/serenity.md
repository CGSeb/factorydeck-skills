# Gates, serenity score and merge

The orchestrator decides here whether a pull request merges without a person. Two parts: **gates**, facts that each hand the pull request to a person whatever the score, and the **serenity score**, how calm you would be merging it without anyone reading it.

`docs/agents/factory.yml` gives `build.auto_merge`, `build.serenity_threshold`, `repository.merge_method`, `protected_paths` and `people.hand_work_to`; operations in **bold** are commands of `docs/agents/git-host.md` (on GitLab, a « pull request » is a merge request). Below, `<main>` is the main branch.

## 1. Gates

Gather the facts in two calls, from the main checkout:

- **Pull request facts**: open, draft, base, head commit, CI, closed issues.
- `sh <skill dir>/gates.sh <branch>`: the head commit, the commits behind `<main>`, the changed lines, each spec touched with its status line and unticked boxes, the changed files under `protected_paths` (entries in prose are listed for you to check by hand), the added suppressions, and the existing files the branch modifies, deletes or renames. Its head must be the head of **Pull request facts**: otherwise the local branch is stale, and you fetch it first.

Read **Pull request diff** only where a fact needs a closer look: a migration among the modified files, a suppression to judge, a change other features rely on.

Every line below that fails is a gate failure. Write each one down in plain words; do not argue any away.

| Gate | Passes when |
| --- | --- |
| Open | it is open and not a draft |
| Base | the pull request targets `<main>` |
| Up to date | it is 0 commits behind `<main>` |
| CI | CI ran on the head commit and every check passed (the passing values are in `docs/agents/git-host.md`) |
| One issue | the pull request closes exactly one issue, and it carries the spec label |
| One spec | the diff updates exactly one spec, whose status is now its done value with every criterion ticked |
| Protected paths | no changed file is under an entry of `protected_paths` in `docs/agents/factory.yml` (the feature map of the verification skill excepted) |
| No suppression | no added line (`+` in the diff) disables a lint rule, a type check or a test: `eslint-disable`, `oxlint-disable`, `@ts-ignore`, `@ts-expect-error`, `@ts-nocheck`, `# type: ignore`, `# noqa`, `.skip(`, `.only(`, `@Disabled`, `#[ignore]` and their equivalents in the repository's languages |
| Migrations | no existing database migration is modified, and no added migration drops, renames, truncates, deletes rows or changes a column type |
| No open blocker | no `blocker` or `major` finding is still open after the last review |

Branch protection on `<main>`, when the repository has it, enforces the CI and up-to-date gates on its own: a merge it refuses is a gate failure too.

## 2. Score

Start at **100** and subtract, using the worker's reports, the reviews and the diff. The score measures the risk of the branch as it is, not the path it took: what a person or the orchestrator decided, and the work that followed from it (a dependency the person chose, a rebase onto a pull request merged first, an adaptation to a contract `<main>` changed), costs nothing. A pull request a person would merge without changing anything scores at least 80.

| Signal | Points |
| --- | --- |
| Each finding fixed after the first review | −2 |
| A second review round was needed because the first found a `blocker` or `major` | −15 |
| Each finding the worker rejected (even if you agree) | −10 |
| Each `minor` finding still open after the second review (not already counted as rejected) | −2 |
| Reviewer confidence `medium` / `low` | −10 / −30 |
| Each product choice the spec did not settle (`product_choices`, `unsettled_choices`, see below) | `cosmetic` −1 (at most −5 in all), `visible` −3 (at most −9 in all), `behavior` −10, `data` −25 |
| Criteria proven only by tests because the local data lacks the case (`partial_proofs`), once | −5 |
| Each limit the reviewer found undeclared (`undeclared_limits`) | −10 |
| Each CI failure fixed after the pull request opened | −5 |
| A flaky check needed a rerun | −10 |
| More than 2000 / 4000 changed lines, lockfiles and generated files excluded | −10 / −25 |
| Migrations added (once, whatever the count): only new tables, columns or indexes / anything else | −5 / −10 |
| A dependency added or upgraded that no person decided | −10 |
| Changes to what other features rely on (see below) | −5 to −15 |
| The review of a rebase's conflict resolution found a problem | −10 |
| Anything else that would make you want a person to look (say what) | your call |

The levels are defined in « Severity of a choice » of the `check-spec` skill. A choice is one fact: when the worker's `product_choices` and the reviewer's `unsettled_choices` name the same one, count it once, at the higher of the two levels, and say in the breakdown when the reviewer ranked it above the worker. A `data` choice alone brings the score to 75, under the default threshold: that is intended, a person merges it. Before you count an entry, look for the spec sentence that settles it: if the spec already says it, do not count it, and say so in the breakdown. `implementation_notes` and `scope_limits` cost nothing: a limit of scope leaves what is delivered fully working, and it reaches the person through the pull request body. Count each fact once, under the line that fits it best. Count `partial_proofs` once, whatever their number, and not at all when an end-to-end test on real infrastructure covers each case. A test a review asked for never costs points.

What other features rely on is what they already use: a shared type, function or module that is changed or removed, the props or the behaviour of an existing component, a public route, command or output format. Adding is not changing: a new export, a new component, or a block added with no change to what was already there costs nothing. Count −5 for a change other features do not notice in their tests, up to −15 for one their tests or verification sheets had to follow. Following a change `<main>` made is not a change of this branch: it was counted on the pull request that made it. A change the spec asks for in so many words (a control moves elsewhere, an indicator goes away) is the person's decision and costs nothing, even when other features' tests or verification sheets had to follow: count only what the worker chose beyond the spec's text, and name in the breakdown the spec sentence that settles each change you leave out.

## 3. Write the breakdown

Write it to a file, in the language for people, for whoever reads the pull request:

```markdown
## Serenity: 85/100 (threshold 80)

- −5: 1 review finding fixed (…). Fixed.
- −10: a limit the reviewer found undeclared (…). Declared in the body.
- −10: a `behavior` choice the spec did not settle (…). Open.

Gates: all passed. Review: 1 round, confidence high.

### What you decide

- The `behavior` choice: <the options>. Recommended: <one>, because <one line>.
```

Each line ends with where that fact stands now: `Fixed.`, `Declared in the body.` or `Open.` A pull request handed to the person ends with « What you decide »: one line per open choice and per risk the review raised, with the option you recommend. A pull request that merges leaves that section out.

## 4. Merge or hand over

- **Auto-merge on, every gate passes and the score reaches the threshold**: **Comment on a pull request** with the breakdown, then **Merge a pull request** with the configured method, the pull request's title and the head commit you scored. The git host refuses the merge if the branch moved since.
- **Otherwise**: **Comment on a pull request** with the breakdown followed by the reasons the merge is refused (each gate failure, or the score below the threshold, or auto-merge off), then **Hand a pull request to the person**. The issue keeps the review label; the worker's worktree stays for follow-up.

Never merge a pull request with a failed gate, and never change the threshold, a gate or `docs/agents/factory.yml` to let one through.
