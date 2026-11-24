---
name: write-spec
description: "Write a feature spec with the person and open its issue on GitHub or GitLab, so build-feature can build it. Interviews the person on the user goal, writes testable acceptance criteria in the repository's spec format (a file of the repository, or the issue body itself), records its dependencies, then runs check-spec. Use when asked to write, draft or add a spec, or to turn an idea into buildable work."
---

# Write a spec

A spec says what a user will be able to do and how anyone can tell it is done. It is the only input a builder agent gets beside the code, so everything a user will see must be in it.

`docs/agents/factory.yml` gives where specs live and their format (`specs`), the issue conventions (`issues`) and the language for people (`people.language`); operations in **bold** are commands of `docs/agents/git-host.md`. It should exist; if not, tell the person to run `/setup-factory` and stop.

`specs.location` decides where the spec is written: `repository` (absent means this) is a file of `specs.folder`; `issue` is the body of its issue, and the issue number is the spec's number. The steps below say where the two differ.

## 1. Understand the feature

Read the product context (`specs.product_context`, each source the way « Product context » of `docs/agents/factory-notes.md` says, only the parts this feature touches), the existing specs (the latest ones and those this feature touches: files of the folder, or with `issue` the issues of the spec label), and the code the feature will change. Then interview the person, in their language, one question at a time, recommended answer first:

- Who uses it and what can they do afterwards that they cannot do now?
- What do they see: the screens, commands or responses, and their wording when it matters.
- What is deliberately left out.
- Which existing specs it builds on.

Ground your recommendations in the code, the existing specs and the product context. Reuse a convention an earlier spec or the product context settled instead of asking it again, and cite it.

Too big for one pull request (more than about a day of work for a person, several independent user goals, or criteria spread over several parts of the product that could ship apart, such as a data layer, an interface and a view of it)? Propose a split into several specs with dependencies between them, and write each one. A large pull request also costs its merge score (`build-feature`'s serenity.md), so a person has to merge it. Count on about 2000 changed lines at most, tests and stories included: a spec that adds stored data (a table, a migration), an API and a new screen together usually goes over, so propose one spec for the data and its API, and one for the screen.

## 2. Write it

With `repository`: next number, one more than the highest in the specs folder; the file name follows `specs.file_name`. With `issue`: write the body in a local file for now; the issue gives the number. Headings follow `specs.format` exactly. Write in the language the existing specs use.

- **Status line**: the first value (draft). With `issue`, no status line: the issue's labels and state carry it.
- **Depends-on line**: the numbers of the specs it needs directly (with `issue`, their issue numbers: `#12, #15`), or « none ». Leave out a spec another listed spec already depends on, directly or through others: the chain records it, and the line stays short as specs pile up.
- **User goal**: one or two sentences, from the user's side.
- **Acceptance criteria**: one checkbox each (`- [ ] …`). Each one is observable and precise enough to prove with a test or a verification recipe: name the wording, the order, the limits, the empty, missing and error cases.
- **Rules**: what a figure means, which records count, thresholds, the data it reads.
- **Expected proof**: how a builder proves it in the real app (a verification feature, a command and its output).
- **Out of scope**: what a builder must not build, so they do not ask.

## 3. Check it

With `repository`, run the `check-spec` skill on the new spec, with the person, before anything else. With `issue`, open the issue first (step 4.1, without the ready label), then run `check-spec` on it: it edits the issue body. Done when it reports nothing open and the spec carries its checked line. Then, with `repository`, set the status to its ready value.

## 4. Open the issue

With `repository`, the spec reaches the main branch first (commit it on a branch and merge it, or commit on the main branch if the person works that way), because a builder starts from the main branch. With `issue`, nothing is committed: the issue is the spec.

1. **Create an issue**: the title format `issues.title` (with `issue`, drop its number part, such as `NNN · `: the issue number is the spec's), the spec's issue label, and a body. With `repository`, the body links the spec on the main branch and repeats its depends-on line with the issue numbers (`Depends on: #12, #15`). With `issue`, the body is the spec written in step 2.
2. When `issues.dependencies` is `blocking-links`, **Add a blocker** for each spec of the depends-on line, even one whose issue is closed: `build-feature` reads the links first. Otherwise the depends-on line is the record.
3. Once the spec carries its checked line (with `repository`, on the main branch), **Move an issue's labels** to add the ready label. Before that, a builder would start from a spec that is not checked, or a main branch that lacks it.

4. Tie this session to the issue, so a dashboard that reads agent logs counts the spec's work on it and on its role: end your last message with the line `Work item: #<n> (spec-writer)` on its own, exactly, with the issue number. The text in parentheses is the role, a lowercase name; other skills write their own. When your agent lets you rename the session, also put `#<n>` at the start of its title.

Done when the issue exists with its labels and dependencies, the person has the link, and the `Work item: #<n> (spec-writer)` line is written.
