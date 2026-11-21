# Gates, serenity score and merge

The orchestrator decides here whether a pull request merges without a person. Two parts: **gates**, facts that each hand the pull request to a person whatever the score, and the **serenity score**, how calm you would be merging it without anyone reading it.

`docs/agents/factory.md` gives the auto-merge setting, the threshold, the merge method, the protected paths and the person to hand work to. Below, `gh` is its GitHub CLI, `<repo>` its repository and `<main>` its main branch.

## 1. Gates

Gather the facts:

```bash
gh pr view <pr> --repo <repo> --json state,isDraft,baseRefName,headRefName,headRefOid,statusCheckRollup,files,closingIssuesReferences
```

```bash
gh api repos/<repo>/compare/<main>...<head sha> --jq .behind_by
```

```bash
gh pr diff <pr> --repo <repo> > <file>
```

Every line below that fails is a gate failure. Write each one down in plain words; do not argue any away.

| Gate | Passes when |
| --- | --- |
| Open | `state` is `OPEN` and `isDraft` is false |
| Base | `baseRefName` is `<main>` |
| Up to date | `behind_by` is 0 |
| CI | at least one check ran on the head commit, and every check concluded `SUCCESS`, `NEUTRAL` or `SKIPPED` |
| One issue | the pull request closes exactly one issue, and it carries the spec label |
| One spec | the diff updates exactly one spec, whose status is now its done value with every criterion ticked |
| Protected paths | no changed file is under a protected path of `docs/agents/factory.md` (the feature map of the verification skill excepted) |
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
| Each product choice the spec did not settle (`product_choices`, see below) | −10 |
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

Before you count a `product_choices` entry, look for the spec sentence that settles it: if the spec already says it, do not count it, and say so in the breakdown. `implementation_notes` and `scope_limits` cost nothing: a limit of scope leaves what is delivered fully working, and it reaches the person through the pull request body. Count each fact once, under the line that fits it best. Count `partial_proofs` once, whatever their number, and not at all when an end-to-end test on real infrastructure covers each case. A test a review asked for never costs points.

What other features rely on is what they already use: a shared type, function or module that is changed or removed, the props or the behaviour of an existing component, a public route, command or output format. Adding is not changing: a new export, a new component, or a block added with no change to what was already there costs nothing. Count −5 for a change other features do not notice in their tests, up to −15 for one their tests or verification sheets had to follow. Following a change `<main>` made is not a change of this branch: it was counted on the pull request that made it.

## 3. Write the breakdown

Write it to a file, in the language for people, for whoever reads the pull request:

```markdown
## Serenity: 85/100 (threshold 80)

- −5: 1 review finding fixed (…)
- −10: a choice the spec did not settle (…)

Gates: all passed. Review: 1 round, confidence high.
```

## 4. Merge or hand over

- **Auto-merge on, every gate passes and the score reaches the threshold**: post the breakdown, then merge with the configured method and the pull request's title:

  ```bash
  gh pr comment <pr> --repo <repo> --body-file <breakdown>
  ```

  ```bash
  gh pr merge <pr> --repo <repo> --squash --delete-branch --subject "<title>" --match-head-commit <head sha>
  ```

  (`--merge` or `--rebase` instead of `--squash` when that is the configured method.) `--match-head-commit` makes GitHub refuse the merge if the branch moved since you scored it.

- **Otherwise**: post the breakdown followed by the reasons the merge is refused (each gate failure, or the score below the threshold, or auto-merge off), then assign the pull request to the person:

  ```bash
  gh pr edit <pr> --repo <repo> --add-assignee <hand work to>
  ```

  GitHub does not let an author request its own review, so the person finds these pull requests under « Assigned to you ». The issue keeps the review label; the worker's worktree stays for follow-up.

Never merge a pull request with a failed gate, and never change the threshold, a gate or `docs/agents/factory.md` to let one through.
