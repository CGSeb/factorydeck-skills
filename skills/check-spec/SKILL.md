---
name: check-spec
description: "Check a spec for product choices it leaves open, before anyone builds it. Ranks every choice a user would see or another feature would depend on by severity, asks the person about those that change a behaviour or the data, and writes the answers into the spec. Use at the end of writing a spec, when asked to check, validate or complete a spec, and from build-feature before it starts a builder."
---

# Check a spec

A spec is ready to build when an agent can build it without inventing anything a user will see. This skill finds what is still open, gets it settled by the person, and writes the answer into the spec.

`docs/agents/factory.yml` gives the spec format (`specs.format`), the labels (`issues.labels`) and the language for people (`people.language`); operations in **bold** are commands of `docs/agents/git-host.md`. It should exist; if not, tell the person to run `/setup-factory` and stop.

With `specs.location: issue`, the spec is the body of its issue: read it with **Read an issue**, and write into it with **Edit an issue body**, reading the body again right before each edit and changing only your own lines (answers, the checked line), so an edit the person made meanwhile is kept. The specs it depends on are the issues its depends-on line names; a missing depends-on line reads as « none », and blocking links still count. Otherwise (`repository`, or no `location`) the spec is a file of `specs.folder`.

It runs in two ways:

- **With the person**, in a session where they invoked it (often right after `write-spec`): ask the questions directly and complete the spec.
- **Before a build**, started by `build-feature`: the person is not there. Ask on the issue and stop (see « Before a build »).

## 1. Read

Read the spec, the product context (each source of `specs.product_context` the way « Product context » of `docs/agents/factory-notes.md` says, only the parts this spec touches), the specs it depends on and the specs already done, then the code and data it relies on: the data model behind each field the criteria show, sample or seed data when a threshold or a bucket depends on real values, and the code the feature will change.

## 2. List what is open

An open choice is anything the spec does not settle and the builder would have to decide, among:

- **What a user sees**: wording of a key fact, units, rounding, order, limits (how many items, which ones first), empty, missing, unknown or error cases, what is shown on a small screen.
- **What a figure means**: which records count, buckets and thresholds, deduplication, which record wins when there are several.
- **How it behaves**: URL or command format and parameter names, what survives a reload or a restart, how it interacts with features already built, keyboard and focus.
- **What other features must agree with**: a convention another spec or the product context already set, or one the next specs will need. Reuse a convention a spec or the product context already settled and cite it (the spec, or the source's path or URL, with the quote), instead of asking again.

A spec that lacks a section of `specs.format` a build needs (the acceptance criteria at least: specs written in issues often have only a user story) is open at `behavior` level. With the person, offer to write the section from the spec's text and the answers. Before a build, name the missing section in the comment.

Six sweeps find what a reading misses, because sample data hides them:

- **Missing values**: for each field the criteria show, find where it is stored. If it can be absent, the spec must say what is shown when it is, even when no sample record lacks it.
- **Coded values**: for each coded field shown (a type, a category, a status), list every value the source or the code allows, not only those in the sample, and check that the spec says how each one is shown.
- **Values that do not apply**: for each grouped or summary entry (a total, an « other » or « none » bucket, a parent of nested items), list the fields that have no meaning for it. The spec must say what each one shows, distinct from how it shows an unknown value.
- **Inputs that can grow**: for each input the feature accepts and each collection it returns (a count, a page, a file, a time range, a batch), the spec must give its upper bound and what happens beyond it.
- **Values a user writes**: for each configuration file, environment variable, command or URL parameter the feature reads, the spec must settle a relative path and a `~` path, an empty value and an empty file, two spellings of one value (a trailing `/`, letter case) and a duplicate entry. A new file format also names how it is parsed: a library the project does not use yet is the person's choice.
- **Events read from a history**: for each history the feature reads or derives from (label changes, state changes, reports, comments), the spec must settle a repeated event, an event with no matching opposite (a removal with no addition), an event whose subject was deleted or renamed since, and two events at the same time.

Choices a user never sees (file layout, internal names, query shape, component split) belong to the builder: leave them out.

### Severity of a choice

Rank each open choice by what happens if the builder gets it wrong, not by its subject. When two levels fit, take the higher one. `build-feature` uses this scale for the worker, the reviewer and the serenity score (the costs are in its serenity.md).

| Level | What a wrong choice does | Examples |
| --- | --- | --- |
| `cosmetic` | Changes no behaviour and no meaning; fixed in one line | colour, spacing, the wording of a label, an icon |
| `visible` | The user sees it, but actions and data stay the same; reversible without a migration | default sort, text of an empty state, column order, display rounding |
| `behavior` | Changes what an action or a flow does | a default that triggers something, confirm or not, what a click chains to, a filtering rule, a URL or command format |
| `data` | Changes what a figure means, what is stored, or a contract others consume; or cannot be taken back | which records count, a threshold or bucket, a new field or migration, an output format other features read |

Only `behavior` and `data` choices are open: ask them, or post them before a build. A `cosmetic` or `visible` choice is left to the builder, who settles it, declares it with its level and pays a few points of serenity for it; do not ask it, and do not list it as open.

For each open choice, write its level, the options you see and the one you recommend, with one line of why. Ground it in the data and the code you read, not in guesses.

Nothing open at `behavior` or `data` level: say so in one line and stop.

## 3. With the person

Ask the questions directly, in the language for people, a few at a time, recommended option first. Then write each answer into the spec where a builder will look for it, without adding sections the format does not have:

- A behaviour a user can observe becomes an **acceptance criterion**, precise enough to be proven by a test or a verification recipe.
- A rule on the data (which records, buckets, thresholds) goes in the **rules** section.
- Something deliberately not built goes in **out of scope**.

Keep the spec's tone and language. Once nothing is left open, add the checked line with today's date (`YYYY-MM-DD`) right under the depends-on line, or update it: `build-feature` then skips the check before building. Then show the person what changed in the spec.

If the person leaves a question open on purpose, write it in out of scope or as a criterion that names the default, so a builder does not ask it again.

When the spec already has an issue (not when `write-spec` runs you: it writes the line itself), end your last message with the work item line of `write-spec` step 4, `Work item: #<issue> (spec-checker)`.

## Before a build

The person is not there and nothing has been built yet. Change no file and no issue body. Write every question in **one** comment, in the language for people, one numbered question per choice, each with its options and the one you recommend, then:

1. **Comment on an issue** with it.
2. **Move an issue's labels** from the working label to the needs-spec label.
3. **Hand an issue to the person**.

The person answers by completing the spec (they can run this skill to do it), then puts the ready label back.

End with one line: `open: none`, or `open: <n> questions posted on #<issue>`.
