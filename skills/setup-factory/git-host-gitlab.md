# Git host: GitLab

Issues, merge requests and CI for this repository live on GitLab. Every operation goes through the [GitLab CLI](https://gitlab.com/gitlab-org/cli), `glab`, run from inside the clone: it infers the project from `git remote`, and `glab api` fills `:id` with it. The factorydeck skills name the operations below in **bold**; run the command written here. `/setup-factory` wrote this file and checked each command against the installed `glab`; edit it when your setup differs.

- CLI: `glab`
- Project: `<group>/<project>`
- A change request is a **merge request**. The skills say « pull request »: read « merge request ». Issues and merge requests are numbered separately (`#12` is an issue, `!12` a merge request).

`glab` takes multi-line text as an argument, not a file: pass `"$(cat <file>)"`.

## Issues

- **List the queue**: `glab issue list --label "<spec>,<ready>" --output json`, then sort by title.
- **Read an issue**: `glab issue view <n> --output json`
- **Open blockers**: `glab api projects/:id/issues/<n>/links`, keeping the links whose `link_type` is `is_blocked_by` and whose `state` is `opened`. Blocking links need GitLab Premium or Ultimate; on the free tier there are none, and the spec's depends-on line is the only record of dependencies.
- **Add a blocker**: `glab issue note <n> --message "/blocked_by #<blocker>"` (a quick action; Premium or Ultimate). On the free tier, skip it: the issue description repeats the spec's depends-on line.
- **Create an issue**: `glab issue create --title "<title>" --label <label> --description "$(cat <file>)" --yes`
- **Edit an issue body**: `glab issue update <n> --description "$(cat <file>)"` (replaces the whole description: read it with **Read an issue** right before).
- **Comment on an issue**: `glab issue note <n> --message "$(cat <file>)"`
- **Move an issue's labels**: `glab issue update <n> --unlabel <from> --label <to>`
- **Hand an issue to the person**: `glab issue update <n> --assignee <person>`
- **List labels**: `glab label list`
- **Create a label**: `glab label create --name <label> --description "<role>"`

## Merge requests

- **Open a pull request**: `glab mr create --source-branch <branch> --target-branch <main> --title "<title>" --description "$(cat <file>)" --yes`
- **Update a pull request's body**: `glab mr update <mr> --description "$(cat <file>)"`
- **Merged pull requests of a branch**: `glab mr list --source-branch <branch> --merged --output json`
- **Pull request facts**: `glab api "projects/:id/merge_requests/<mr>?include_diverged_commits_count=true"` gives `state`, `draft`, `target_branch`, `source_branch`, `sha`, `diverged_commits_count` (commits behind) and `head_pipeline.status`; `glab api projects/:id/merge_requests/<mr>/diffs` gives the changed files (`new_path`, `new_file`, `diff`); `glab api projects/:id/merge_requests/<mr>/closes_issues` gives the issues it closes. Passing pipeline status: `success`.
- **Commits behind main**: `diverged_commits_count` from the facts above.
- **Pull request diff**: `glab mr diff <mr>`
- **Read pull request comments**: `glab mr view <mr> --comments`
- **Comment on a pull request**: `glab mr note <mr> --message "$(cat <file>)"`
- **Merge a pull request**: `glab mr merge <mr> --squash --remove-source-branch --squash-message "<title>" --sha <head sha> --yes` (without `--squash` for a merge commit, `--rebase` to rebase). GitLab refuses it if the branch moved since `<head sha>`. If the installed `glab` defaults to merging when the pipeline succeeds, turn that off with its auto-merge flag: the orchestrator merges only after its own checks.
- **Hand a pull request to the person**: `glab mr update <mr> --assignee <person>`

A merge request description containing `Closes #<n>` closes issue `<n>` when it merges into the default branch.

## CI

- **Watch CI**: `glab ci status --branch <branch> --live`. No pipeline for the branch means no CI ran.
- **Failed CI log**: list the failed jobs with `glab api "projects/:id/pipelines/<pipeline id>/jobs?scope[]=failed"`, then `glab ci trace <job id>`.

## Wiki

- **Read a wiki page**: `glab api "projects/:id/wikis/<slug>"` (the page's Markdown is its `content` field), where `<slug>` ends the page URL (`…/-/wikis/<slug>`, its `/` written `%2F`). It reads the page where it is, nothing is copied; private wikis work with the logged-in `glab`. A 404 means no such page, or the wiki is turned off.

## Main branch protection

- **Protect the main branch**: `glab api -X PUT projects/:id -f only_allow_merge_if_pipeline_succeeds=true -f only_allow_merge_if_all_discussions_are_resolved=false`, and protect the branch against direct pushes: `glab api -X POST projects/:id/protected_branches -f name=<main> -f push_access_level=0 -f merge_access_level=40`. Needs the Maintainer role; both work on the free tier.
