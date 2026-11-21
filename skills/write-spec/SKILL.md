---
name: write-spec
description: "Write a feature spec with the person and open its issue on GitHub or GitLab, so build-feature can build it. Interviews the person on the user goal, writes testable acceptance criteria in the repository's spec format, records its dependencies, then runs check-spec. Use when asked to write, draft or add a spec, or to turn an idea into buildable work."
---

# Write a spec

A spec says what a user will be able to do and how anyone can tell it is done. It is the only input a builder agent gets beside the code, so everything a user will see must be in it.

`docs/agents/factory.md` gives the specs folder, the spec format, the issue conventions and the language for people; operations in **bold** are commands of `docs/agents/git-host.md`. It should exist; if not, tell the person to run `/setup-factory` and stop.

## 1. Understand the feature

Read the product context named in `docs/agents/factory.md`, the specs already in the folder (the latest ones and those this feature touches), and the code the feature will change. Then interview the person, in their language, one question at a time, recommended answer first:

- Who uses it and what can they do afterwards that they cannot do now?
- What do they see: the screens, commands or responses, and their wording when it matters.
- What is deliberately left out.
- Which existing specs it builds on.

Ground your recommendations in the code and the existing specs. Reuse a convention an earlier spec settled instead of asking it again, and cite it.

Too big for one pull request (more than about a day of work for a person, or several independent user goals)? Propose a split into several specs with dependencies between them, and write each one.

## 2. Write it

Next number: one more than the highest in the specs folder. File name and headings follow `docs/agents/factory.md` exactly. Write in the language the existing specs use.

- **Status line**: the first value (draft).
- **Depends-on line**: the numbers of the specs it needs, or « none ».
- **User goal**: one or two sentences, from the user's side.
- **Acceptance criteria**: one checkbox each (`- [ ] …`). Each one is observable and precise enough to prove with a test or a verification recipe: name the wording, the order, the limits, the empty, missing and error cases.
- **Rules**: what a figure means, which records count, thresholds, the data it reads.
- **Expected proof**: how a builder proves it in the real app (a verification feature, a command and its output).
- **Out of scope**: what a builder must not build, so they do not ask.

## 3. Check it

Run the `check-spec` skill on the new spec, with the person, before anything else. Done when it reports nothing open and the spec carries its checked line. Then set the status to its ready value.

## 4. Open the issue

The spec reaches the main branch first (commit it on a branch and merge it, or commit on the main branch if the person works that way), because a builder starts from the main branch.

1. **Create an issue**: the title format from `docs/agents/factory.md`, the spec's issue label, and a body that links the spec on the main branch and repeats its depends-on line with the issue numbers (`Depends on: #12, #15`).
2. When `docs/agents/factory.md` records dependencies as blocking links, **Add a blocker** for each spec it depends on, even one whose issue is closed: `build-feature` reads the links first. Otherwise the depends-on line is the record.
3. Once the spec is on the main branch with its checked line, **Move an issue's labels** to add the ready label. Before that, a builder would start from a main branch that lacks the spec.

Done when the issue exists with its labels and dependencies, and the person has the link.
