---
name: check-bug
description: "Check a bug report for what a debugger would have to guess: a missing section, steps that cannot be followed, an expected behaviour no test can assert, a missing version, or an expected behaviour a spec contradicts. Completes the report with the person, or posts the questions on the issue. Use when asked to check or complete a bug report, at the end of report-bug, and from fix-bug before a fix."
---

# Check a bug report

A bug report is ready to fix when a debugger can reproduce the bug and know when it is fixed without guessing. This skill finds every gap, gets it filled by the person, and writes the answers into the report. It never reproduces the bug: never run the application, the tests or the checks, and never change code. Reproducing is `fix-bug`'s first step.

`docs/agents/factory.yml` gives the bug settings (`bugs`), the depends-on and checked lines (`specs.format.depends_on_line`, `specs.format.checked_line`), the labels (`issues.labels`) and the language for people (`people.language`); operations in **bold** are commands of `docs/agents/git-host.md`. Without `factory.yml`, say it is missing, tell the person to run `/setup-factory`, and stop. With a `factory.yml` that has no `bugs` section, say the repository does not use bug tickets yet, tell the person to run `/setup-factory` to add them, and stop. Change nothing in either case.

The report is the body of its issue, whatever `specs.location` says. Read it with **Read an issue**, and write into it with **Edit an issue body**, reading the body again right before each edit and changing only the lines you add or complete, so an edit the person made meanwhile is kept.

It runs in two ways:

- **With the person**, in a session where they invoked it, or at the end of `report-bug`: ask the questions directly and complete the report.
- **Before a fix**, started by `fix-bug`: the person is not there. Ask on the issue and stop (see « Before a fix »).

## 1. Read

Read the report, then the product context (each source of `specs.product_context` the way « Product context » of `docs/agents/factory-notes.md` says, only the parts the bug touches), the specs and the code of the part of the product the report names (its `Likely in:` paths first, when the environment section has them), and the open issues its depends-on line names.

## 2. List the gaps

A gap is one of these, and only these:

- **Missing section**: a heading of `bugs.format.sections` that is absent, or present with nothing under it.
- **Steps that need guessing**: a missing starting state (data, configuration, account, page), an input not given exactly (« a long name » instead of the name), or a step that says what to reach rather than what to do (« get the list to fail »). A steps section that starts with `Not reproducible on demand yet.` is a gap until the person gives steps.
- **Expected behaviour no test can assert**: « should work », « should be faster » with no figure, « should look right ». It must name what a test would check: a value, a message, a state, a limit.
- **Environment without a version**: no version or commit, when the behaviour may depend on it (anything but a bug that the code on the main branch plainly still has).
- **Expected behaviour a spec contradicts**: the expected section asks for the opposite of a sentence of a spec or of the product context. It may not be a bug: the gap quotes that sentence and its source (the spec's issue or path, or the source's path or URL). The person decides; never close the issue.

Every gap is open: there are no severity levels here, because the debugger would have to guess each one. For each gap, propose an answer when the code or the product context suggests one, with one line of why.

No gap: write the checked line (step 3; not « Before a fix »), say so in one line, and end with `open: none`.

## 3. The checked line

The checked line is `specs.format.checked_line` followed by today's date (`YYYY-MM-DD`), right under the depends-on line (at the top of the body when the report has none). It means the four sections are filled, the steps can be followed without guessing, and the expected behaviour can be asserted by a test. It does not mean the bug was reproduced.

- No gap: write it, or keep the one already there as it is.
- A gap found with the person: remove a checked line already there until every gap is filled, then write it with today's date.
- « Before a fix » never edits the body, even with no gap: `fix-bug` only runs it on reports without a checked line, and starts the debugger on `open: none`.

## 4. With the person

Ask about the gaps in `people.language`, a few at a time, recommended answer first. Write each answer into its section of the body: steps as numbered steps, the expected behaviour as what a test would check, the version as a bullet of the environment section. Keep the report's tone and language, and add no section the format does not have.

A gap the person cannot fill (they do not know how to trigger the bug, or it happens only sometimes) stays open: write no checked line, say what would close it (the exact steps, the data, the version), and end with `open: <n> gaps left on #<issue>`. Otherwise write the checked line and end with `open: none`. Show the person what changed in the body.

When the person started it on an existing issue, end your last message with `Work item: #<issue> (bug-checker)` on its own line. When `report-bug` started it, `report-bug` writes its own line instead.

## Before a fix

The person is not there and nothing has been fixed yet. Change no issue body. Write every gap in **one** comment, in `people.language`, one numbered question per gap, each with the answer you propose when you have one, then:

1. **Comment on an issue** with it.
2. **Move an issue's labels** from the working label to the needs-spec label.
3. **Hand an issue to the person**.

The person answers by completing the report (they can run this skill to do it), then puts the ready label back.

With no gap, post nothing. End with one line: `open: none`, or `open: <n> questions posted on #<issue>`. This mode runs on the model of `agents.models.spec_check`.
