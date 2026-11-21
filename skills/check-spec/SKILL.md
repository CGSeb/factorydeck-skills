---
name: check-spec
description: "Check a spec for product choices it leaves open, before anyone builds it. Lists every choice a user would see or another feature would depend on, asks the person, and writes the answers into the spec. Use at the end of writing a spec, when asked to check, validate or complete a spec, and from build-feature before it starts a builder."
---

# Check a spec

A spec is ready to build when an agent can build it without inventing anything a user will see. This skill finds what is still open, gets it settled by the person, and writes the answer into the spec.

`docs/agents/factory.md` gives the spec format, the labels and the language for people. It should exist; if not, tell the person to run `/setup-factory` and stop.

It runs in two ways:

- **With the person**, in a session where they invoked it (often right after `write-spec`): ask the questions directly and complete the spec.
- **Before a build**, started by `build-feature`: the person is not there. Ask on the GitHub issue and stop (see « Before a build »).

## 1. Read

Read the spec, the product context, the specs it depends on and the specs already done, then the code and data it relies on: the data model behind each field the criteria show, sample or seed data when a threshold or a bucket depends on real values, and the code the feature will change.

## 2. List what is open

An open choice is anything the spec does not settle and the builder would have to decide, among:

- **What a user sees**: wording of a key fact, units, rounding, order, limits (how many items, which ones first), empty, missing, unknown or error cases, what is shown on a small screen.
- **What a figure means**: which records count, buckets and thresholds, deduplication, which record wins when there are several.
- **How it behaves**: URL or command format and parameter names, what survives a reload or a restart, how it interacts with features already built, keyboard and focus.
- **What other features must agree with**: a convention another spec already set, or one the next specs will need. Reuse a convention a spec already settled and cite it, instead of asking again.

Two sweeps find what a reading misses, because sample data hides them:

- **Missing values**: for each field the criteria show, find where it is stored. If it can be absent, the spec must say what is shown when it is, even when no sample record lacks it.
- **Coded values**: for each coded field shown (a type, a category, a status), list every value the source or the code allows, not only those in the sample, and check that the spec says how each one is shown.

Choices a user never sees (file layout, internal names, query shape, component split) belong to the builder: leave them out.

For each choice, write the options you see and the one you recommend, with one line of why. Ground it in the data and the code you read, not in guesses.

Nothing open: say so in one line and stop.

## 3. With the person

Ask the questions directly, in the language for people, a few at a time, recommended option first. Then write each answer into the spec where a builder will look for it, without adding sections the format does not have:

- A behaviour a user can observe becomes an **acceptance criterion**, precise enough to be proven by a test or a verification recipe.
- A rule on the data (which records, buckets, thresholds) goes in the **rules** section.
- Something deliberately not built goes in **out of scope**.

Keep the spec's tone and language. Once nothing is left open, add the checked line with today's date (`YYYY-MM-DD`) right under the depends-on line, or update it: `build-feature` then skips the check before building. Then show the person what changed in the spec.

If the person leaves a question open on purpose, write it in out of scope or as a criterion that names the default, so a builder does not ask it again.

## Before a build

The person is not there and nothing has been built yet. Change no file. Write every question in **one** comment, in the language for people, one numbered question per choice, each with its options and the one you recommend:

```bash
gh issue comment <issue> --repo <repo> --body-file <file>
```

```bash
gh issue edit <issue> --repo <repo> --remove-label <working label> --add-label <needs-spec label> --add-assignee <hand work to>
```

The person answers by completing the spec (they can run this skill to do it), then puts the ready label back.

End with one line: `open: none`, or `open: <n> questions posted on #<issue>`.
