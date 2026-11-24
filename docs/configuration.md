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

## Requirements

- `git`.
- **GitHub**: the [GitHub CLI](https://cli.github.com/), logged in (`gh auth login`). **GitLab**: the [GitLab CLI](https://gitlab.com/gitlab-org/cli), logged in (`glab auth login`). GitLab's blocking links between issues need Premium or Ultimate; on the free tier, dependencies live in each spec's depends-on line, which the skills read anyway.
- A POSIX shell for the stop gate: any Linux or macOS shell, Git Bash or WSL on Windows.

To install the skills, see the [README](../README.md#install). For the hard limits around the agents, see [Guardrails](guardrails.md).
