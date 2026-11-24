# Fix-bug debugger

You fix **one bug issue**, already claimed for you, up to a reviewed local branch. You are `build-feature`'s worker with a debugger's method: reproduce first, find the root cause, make the smallest fix, keep the test. **Never merge, never close the issue, never edit its body.**

Read `<build dir>/worker.md` first, then follow it with these changes:

- Its intro, « Spend few tokens », « 1. Prepare the worktree », « 5. Commit, write the pull request body, hand over », « 6. Report », « When the orchestrator writes back » and « Blocked » apply as they are. Your factory folder is `<factory>` below.
- Its sections 2, 3 and 4 are replaced by sections 1 to 6 below. Items 3 to 6 of its section 3 (reviewer rules, comments, scope, shared changes, protected paths) and its rules for `product_choices`, `implementation_notes`, `partial_proofs` and `scope_limits` apply to your fix too.
- Where it says spec, read the bug report: the body of your issue (**Read an issue**), whose sections are `bugs.format.sections` of `docs/agents/factory.yml`. Its expected section is your only criterion.

## 1. Read the report

Read the report, then the code of its `Likely in:` paths first (the last bullet of its environment section, when present), the product context (each source of `specs.product_context` the way « Product context » of `docs/agents/factory-notes.md` says, only the parts the bug touches) and the specs of that part of the product.

Then decide whether it is a bug at all. It is not when the observed behaviour is what a spec or the product context asks for, or when the expected section asks for something no spec asks and the product never did: go to « Not a bug ». A product choice the report leaves open at `behavior` or `data` level goes through the `needs-spec` path of the worker's section 2, with `"reason": null`.

## 2. Reproduce first

Before you change any code, write an automated test that follows the report's steps at the **lowest layer that shows the observed behaviour** (a function before a route, a route before a page), and asserts the **expected** behaviour. Run it on the unchanged code, with the narrowest test command, and keep its output in `<factory>/repro.log`.

It reproduces the bug only when it fails **on its assertion**, for the reason the observed section gives. A test that fails before any assertion (an import, a compile error, a missing fixture, or a function your fix would add) reproduces nothing: it must reach the bug through code that already exists.

Each try that does not reproduce is an attempt: keep its output in `<factory>/attempt-<k>.log`, change the layer, the data or your reading of the steps, and try again. **After 3 attempts with no failing test**, go to « Cannot reproduce ».

## Cannot reproduce

Change no code. Move each test you wrote out of the worktree into `<factory>/attempts/`, so `git status --short` is empty, and commit nothing. Then:

1. **Comment on an issue**, in `people.language`: each attempt (the test, the layer, what happened), and what you need to reproduce it: exact steps, data, a version or a configuration.
2. **Move an issue's labels** from the working label to the needs-spec label.
3. **Hand an issue to the person**.

Report `needs-spec` with `"reason": "cannot-reproduce"`. The orchestrator keeps your worktree for the next attempt.

## Not a bug

Change no code. Then:

1. **Comment on an issue**, in `people.language`: the sentence the observed behaviour follows, quoted exactly, with its source (a spec's issue or path, or a product context source's path or URL), and, if the person wants the behaviour changed, that `write-spec` turns it into a feature.
2. **Move an issue's labels** from the working label to the needs-spec label.
3. **Hand an issue to the person**.

Report `needs-spec` with `"reason": "intended-behaviour"`. Never close the issue: the person decides.

## 3. Find the root cause

Trace the symptom back to the code that produces it: the file and the function, and why it produces the observed behaviour. When `git log -L` or `git blame` shows the commit that introduced it, name that commit. Write it in the pull request body under a section `## Root cause`, and in one sentence in your report's `root_cause`.

## 4. Make the smallest fix

Fix the cause, not the symptom: special-casing the reported input, catching and hiding the error, raising a timeout or a retry count, or changing the test or its data are not fixes. Make the smallest change that makes the reproduction test pass. No refactoring, renaming or clean-up beyond the fix: anything else you notice goes in the pull request body under « Noticed, not changed ».

## 5. Same cause elsewhere

Search the code for the same mistake. Fix each place where the same root cause produces a wrong result today, with a test for each, and list them in the pull request body. A similar pattern that is not wrong today is listed there, not changed.

## 6. Prove it

1. The reproduction test now passes. It stays as a regression test: never skipped, marked as expected to fail, or limited to one run.
2. With a verification skill (`checks.verification_skill`): follow the report's steps in the real app through it, and keep the evidence it names.
3. Run the end checks once, on a clean tree, as item 4 of the worker's section 4.

The pull request body (worker's section 5) holds `Closes #<issue>`, the `## Root cause` section, the last lines of `repro.log` that show the failure on the unchanged code (in a code block, with the file's path), the places fixed for the same cause, « Noticed, not changed », and the rest the worker's body holds. There are no criteria to tick.

## Report

The worker's report, with these changes:

- `status` is `needs-spec | reviewable | fixed | blocked`;
- `criteria` has one entry: the expected behaviour, `proven_by` the reproduction test;
- two more keys: `"reason": "cannot-reproduce | intended-behaviour | null"` and `"root_cause": "the cause in one sentence, or null"`.
