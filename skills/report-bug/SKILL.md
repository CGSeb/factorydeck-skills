---
name: report-bug
description: "Turn a bug the person describes in a few words into a bug issue on GitHub or GitLab that fix-bug can take without asking again: interviews them on what happens, what should happen, the steps and the environment, finds where in the code it probably lives, checks the open bugs for the same one, opens the issue and runs check-bug on it. Use when the person reports a bug, a regression, or something that does not work as expected."
---

# Report a bug

A bug report says what happens, what should happen, how to make it happen and where, precisely enough that a debugger can reproduce it and know when it is fixed. This skill writes it with the person and opens its issue. It never reproduces the bug: never run the application, the tests or the checks, never start services, and never write or commit code. Reproducing is `fix-bug`'s first step.

`docs/agents/factory.yml` gives the bug settings (`bugs`), the depends-on line (`specs.format.depends_on_line`), the labels (`issues.labels`), how dependencies are recorded (`issues.dependencies`) and the language for people (`people.language`); operations in **bold** are commands of `docs/agents/git-host.md`. Without `factory.yml`, tell the person to run `/setup-factory` and stop. With a `factory.yml` that has no `bugs` section, say the repository does not use bug tickets yet, tell the person to run `/setup-factory` to add them, and stop. Open no issue in either case.

## 1. Interview

Ask in `people.language`, one question at a time, recommended answer first when you can propose one, until each section of `bugs.format.sections` has its content:

- **observed**: what happens, with the exact message, value or state when there is one;
- **expected**: what should happen instead, as something a test can check (a value, a message, a state, a limit);
- **steps**: numbered steps from a stated starting state (data, configuration, account, page), with exact inputs;
- **environment**: version or commit, operating system, browser or runtime, configuration, and the data it needs.

Skip a question the person's messages already answer. When they cannot say how to trigger the bug, or it happens only sometimes, stop asking about steps: write what is known, with `Not reproducible on demand yet.` as the first line of the steps section.

Replace any token, password, key or personal data the person pastes (logs, configuration) with `<redacted>`, and tell them you did.

## 2. Locate

Read the code, and the product context the way « Product context » of `docs/agents/factory-notes.md` says, only the parts the bug touches, to find the files where the bug probably lives. Reading only: no command beyond reading files, no app, no test run. Add them as the last bullet of the environment section, `Likely in: \`<path>\`, \`<path>\``, at most 5 paths, the most likely first; leave the bullet out when you find none.

## 3. Same bug already reported?

**List open issues of a label** with `bugs.label` (it returns the 100 most recently updated). A similar issue is one whose title or body describes the same symptom on the same part of the product. Closed issues are not searched.

When some look similar, show the person at most 5, as `#<n> <title>`, and ask whether to open a new issue or add this report to one of them. To add it, **Comment on an issue** with the report (the four sections), open no issue, add no label, and go to step 6 with that issue's number.

## 4. Open the issue

Show the person the title and the body, and let them edit both:

- **Title**: a plain name that states the symptom, with no number part and no `Bug:` prefix, such as `Overview shows 0 tokens after midnight`.
- **Body**, in `people.language`: the depends-on line (`specs.format.depends_on_line` followed by `none`, or the issues the person says must be fixed first, as `#12, #15`), then the four sections with the exact headings of `bugs.format.sections`, in the order observed, expected, steps, environment.

Then:

1. When `bugs.label` is not among the labels (**List labels**), **Create a label** for it.
2. **Create an issue** with the title, `bugs.label` and the body.
3. When `issues.dependencies` is `blocking-links`, **Add a blocker** for each issue of the depends-on line.

## 5. Check it

Run the `check-bug` skill on the new issue, with the person. It fills the gaps and writes the checked line.

- It ends `open: none`: **Move an issue's labels** to add the ready label (`issues.labels.ready`; nothing to remove). `fix-bug` can take the bug.
- It leaves gaps open (always the case with `Not reproducible on demand yet.`): add no ready label, and tell the person what would make it ready (the steps, the data, the version) and that they put the ready label once it is there.

## 6. Tie the session to the issue

End your last message with `Work item: #<n> (bug-reporter)` on its own line, with the number of the issue you opened or commented on. It replaces the line `check-bug` would write. When your agent lets you rename the session, also put `#<n>` at the start of its title.

Done when the issue exists with `bugs.label` and its blockers (or the comment is posted), `check-bug` has run on it, the ready label is on when it ended `open: none`, the person has the link, and the work item line is written.
