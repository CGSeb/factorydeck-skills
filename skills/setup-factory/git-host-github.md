# Git host: GitHub

Issues, pull requests and CI for this repository live on GitHub. Every operation goes through the [GitHub CLI](https://cli.github.com/), `gh`, run from inside the clone: it infers the repository from `git remote`. The factorydeck skills name the operations below in **bold**; run the command written here. `/setup-factory` wrote this file and checked each command against the installed `gh`; edit it when your setup differs.

- CLI: `gh`
- Repository: `<owner>/<repo>`
- A change request is a **pull request**, numbered in the same space as issues.

Pass multi-line text as a file (`--body-file <file>`); with a Windows `gh.exe` under WSL, convert the path with `wslpath -w` first.

## Issues

- **List the queue**: `gh issue list --label <spec> --label <ready> --state open --json number,title --jq 'sort_by(.title)'`
- **Read an issue**: `gh issue view <n> --json number,title,body,labels,state`
- **Open blockers**: `gh api repos/<owner>/<repo>/issues/<n>/dependencies/blocked_by --jq '[.[] | select(.state == "open") | .number]'`
- **Add a blocker**: `gh api -X POST repos/<owner>/<repo>/issues/<n>/dependencies/blocked_by -F issue_id=<id>`, where `<id>` is the blocker's database id: `gh api repos/<owner>/<repo>/issues/<blocker> --jq .id`, not its number.
- **Create an issue**: `gh issue create --title "<title>" --label <label> --body-file <file>`
- **Comment on an issue**: `gh issue comment <n> --body-file <file>`
- **Move an issue's labels**: `gh issue edit <n> --remove-label <from> --add-label <to>`
- **Hand an issue to the person**: `gh issue edit <n> --add-assignee <person>`
- **List labels**: `gh label list --limit 200`
- **Create a label**: `gh label create <label> --description "<role>"`

## Pull requests

- **Open a pull request**: `gh pr create --base <main> --head <branch> --title "<title>" --body-file <file>`
- **Update a pull request's body**: `gh pr edit <pr> --body-file <file>`
- **Merged pull requests of a branch**: `gh pr list --head <branch> --state merged --json number --jq length`
- **Pull request facts**: `gh pr view <pr> --json state,isDraft,baseRefName,headRefName,headRefOid,statusCheckRollup,files,closingIssuesReferences`. Passing check conclusions: `SUCCESS`, `NEUTRAL`, `SKIPPED`.
- **Commits behind main**: `gh api repos/<owner>/<repo>/compare/<main>...<head sha> --jq .behind_by`
- **Pull request diff**: `gh pr diff <pr>`
- **Read pull request comments**: `gh pr view <pr> --comments`
- **Comment on a pull request**: `gh pr comment <pr> --body-file <file>`
- **Merge a pull request**: `gh pr merge <pr> --squash --delete-branch --subject "<title>" --match-head-commit <head sha>` (`--merge` or `--rebase` for the other merge methods). GitHub refuses it if the branch moved since `<head sha>`.
- **Hand a pull request to the person**: `gh pr edit <pr> --add-assignee <person>`. GitHub does not let an author request its own review; the person finds it under « Assigned to you ».

A pull request body containing `Closes #<n>` closes issue `<n>` when it merges.

## CI

- **Watch CI**: `gh pr checks <pr> --watch`. « no checks reported » means no CI ran.
- **Failed CI log**: `gh run view <run id> --log-failed` (the run id is in the failing check's link).

## Main branch protection

- **Protect the main branch**: `gh api -X PUT repos/<owner>/<repo>/branches/<main>/protection --input <file>` with `{"required_status_checks": {"strict": true, "contexts": [<check names>]}, "enforce_admins": false, "required_pull_request_reviews": null, "restrictions": null}`. Needs admin rights; private repositories need a paid plan.
