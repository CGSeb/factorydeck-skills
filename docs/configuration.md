# Configuration

Nothing about your project is hard-coded. `docs/agents/factory.yml` holds every setting in plain YAML, validated by [a JSON Schema](../skills/setup-factory/factory.schema.json): edit it by hand, or from [FactoryDeck](https://github.com/CGSeb/factorydeck) once it connects your repositories. The skills read your spec headings, your labels, your check command, your models and your language from it. What needs more than a value goes in `docs/agents/factory-notes.md`, one section each: notes on the checks, the commit convention, main branch protection and the rules for the reviewer. `docs/agents/git-host.md` holds the exact `gh` or `glab` command for each operation the skills name, so a CLI that changes a flag is fixed in one place. Keep an existing spec format; `setup-factory` maps it instead of replacing it.

The optional `project.name` is the name tools such as FactoryDeck show for the project; without it, they use the name of the repository's root folder. The skills do not read it.

## Where specs and context live

A feature spec lives in one place for the whole project, set by `specs.location`:

- `repository` (the default when the key is absent): a file of `specs.folder`, linked from its issue.
- `issue`: the body of its issue, a user story with its acceptance criteria. `specs.folder` and `specs.file_name` are `none`; the issue's labels and state carry the status, `check-spec` writes its answers and checked line into the body, and the worker ticks the criteria there.

```yaml
specs:
  location: issue
  folder: none
  file_name: none
```

The project-wide spec (the product, its vocabulary, the conventions every feature shares) goes in `specs.product_context`: `none`, one path, or a list of repository paths (from the root), wiki pages and external pages. « Product context » in `factory-notes.md` says how an agent reads each one that is not a file, such as **Read a wiki page** or a connector. Every source is read where it is: nothing is cloned or copied, unless the person keeps a copy in the repository on purpose.

```yaml
specs:
  product_context:
    - README.md
    - https://github.com/acme/shop/wiki/Product
    - https://www.notion.so/acme/Shop-glossary-0123abcd
```

The product context never goes into `AGENTS.md`: the instructions file is loaded in every session, on every turn, and holds the rules for working on the code. The context is reference material: an agent reads it when a task needs it, and only the part the task touches.

Instructions for agents go to `AGENTS.md`. With Claude Code, `CLAUDE.md` imports it with a single `@AGENTS.md` line.

## Bug tickets

The optional `bugs` section says how the repository handles bug tickets. Without it, the repository does not use the bug skills, and the file stays valid.

```yaml
bugs:
  label: bug
  branch_name: "fix/NNN-short-name"
  pull_request_title: "fix: <Subject>"
  format:
    sections:
      observed: "## Observed"
      expected: "## Expected"
      steps: "## Steps to reproduce"
      environment: "## Environment"
```

- `label`: the label that marks an issue as a bug. It must differ from every label of `issues.labels`, ignoring letter case (labels are case-insensitive on GitHub): otherwise `build-feature` would take bugs, or a flow label would mark every issue as a bug. The schema cannot compare two fields, so `setup-factory` enforces it.
- `branch_name`: the branch of a fix, with `NNN` (the issue number) and a short name, like `build.branch_name`.
- `pull_request_title`: the pull request title of a fix, with `<Subject>`, like `build.pull_request_title`.
- `format.sections`: the exact headings of a bug report: what happens (`observed`), what should happen (`expected`), how to make it happen (`steps`), and where (`environment`).

A bug report always lives in the body of its issue, whatever `specs.location` says. It reuses the depends-on and checked lines of `specs.format`, and no other key of it. Its title is a plain name, with no number part. A bug issue carries `bugs.label` instead of `issues.labels.spec`, plus the same flow labels as a spec (`ready`, `working`, `review`, `needs_spec`, `blocked`): `build-feature` takes only issues with the spec label, so it never takes a bug.

A bug goes through `report-bug` → `check-bug` → `fix-bug`. [`report-bug`](../skills/report-bug/SKILL.md) interviews you on the bug, reads the code to name the files it probably lives in (a `Likely in:` bullet of the environment section), shows you the open bugs that look like it, then opens the issue with `bugs.label` and runs `check-bug` with you; it adds the ready label when nothing is left open. It never runs the app or the tests: reproducing is `fix-bug`'s first step. [`check-bug`](../skills/check-bug/SKILL.md) is to a bug report what `check-spec` is to a spec: it writes the checked line once the four sections are filled, the steps can be followed without guessing and the expected behaviour can be asserted by a test. Before a fix, it posts its questions on the issue and moves it to the needs-spec label instead.

[`fix-bug`](../skills/fix-bug/SKILL.md) is `build-feature` for the bugs of the queue (`bugs.label` and the ready label), oldest first, within `build.parallel_workers`. It runs `check-bug` before a fix on a report without a checked line, then starts one debugger per bug, on a branch named after `bugs.branch_name`. The debugger writes a test that fails on the unchanged code for the reported reason (its output stays in `repro.log` of the branch's factory folder), finds the root cause (a `## Root cause` section of the pull request body), makes the smallest fix, fixes the same mistake wherever it gives a wrong result, and keeps the test as a regression test. After 3 attempts with no failing test, or when the behaviour is what a spec asks for, it changes no code, asks on the issue and moves it to the needs-spec label. The fix is then reviewed, shipped, scored and merged as a feature, its pull request titled after `bugs.pull_request_title`, with gates of its own: « One issue » requires `bugs.label`, and « No spec » requires that no spec changes.

A fix has [its own reviewer](../skills/fix-bug/reviewer.md), on top of `build-feature`'s. Every round, it runs the branch's test files on the main branch's code, in a temporary worktree (output in `repro-main.log` of the branch's factory folder): the fix is trusted only when a test fails there on an assertion. A test that passes on main, fails before any assertion (an import of a function the fix adds), or no test at all is a `blocker` finding sent back to the debugger. It checks the `## Root cause` section on main's code, and a fix that hides the symptom (special-casing the input, swallowing the error, raising a timeout, changing the test) is a `major` finding. Two gates follow from it: « Reproduced » (the test failed on main on an assertion) and « Root cause » (the section exists and the reviewer confirmed it).

The serenity report of a fix has two more lines right after its `Review:` line, in a fixed format that FactoryDeck reads:

```markdown
Root cause: total() starts its loop at index 1, so the first line of a cart is never added.
Reproduced: failed on main
```

`Root cause:` holds one sentence of at most 200 characters (cut with `…`), or `none`. `Reproduced:` is one of `failed on main`, `passed on main`, `did not run on main` and `no test`. A feature's report does not have them.

## Requirements

- `git`.
- **GitHub**: the [GitHub CLI](https://cli.github.com/), logged in (`gh auth login`). **GitLab**: the [GitLab CLI](https://gitlab.com/gitlab-org/cli), logged in (`glab auth login`). GitLab's blocking links between issues need Premium or Ultimate; on the free tier, dependencies live in each spec's depends-on line, which the skills read anyway.
- A POSIX shell for the stop gate: any Linux or macOS shell, Git Bash or WSL on Windows.

To install the skills, see the [README](../README.md#install). For the hard limits around the agents, see [Guardrails](guardrails.md).
