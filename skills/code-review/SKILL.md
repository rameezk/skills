---
name: code-review
description: Review a change along two independent axes - Standards (does it follow this repo's conventions and stay free of code smells?) and Spec (does it faithfully implement the ticket and spec it came from?). Runs both as parallel sub-agents and reports them side by side. Use to review a branch, a PR, or work in progress, or when asked to "review since X".
---

# Code Review

Review the diff between `HEAD` and a fixed point along two axes that are kept deliberately apart:

- **Standards** - does the change follow this repo's documented conventions and stay clear of code smells?
- **Spec** - does the change faithfully implement the ticket it came from, and the spec behind it?

Each axis runs as its **own sub-agent in an isolated context**, so neither pollutes the other's judgement, and then this skill aggregates their findings without merging or re-ranking them. That separation is the whole point (see [Why two axes](#why-two-axes)): a change can pass one axis and fail the other, and a single blended verdict lets the pass hide the fail.

This is a read-only pass. It reports; it does not touch code. Fixing what it finds is a separate step the user chooses - a fresh [[tdd]] cycle for a real defect, a local cleanup for a smell - not something this skill folds in. Security is a separate axis entirely: run [[security-review]] for it; this skill does not cover vulnerabilities.

## Process

### 1. Pin the fixed point

The fixed point is whatever the user gives - a commit SHA, a branch, a tag, `main`, `HEAD~5`. If they name none, ask; do not assume `main`.

Capture the diff once, three-dot so the comparison is against the merge-base: `git diff <fixed-point>...HEAD`. Note the commits too: `git log <fixed-point>..HEAD --oneline`. Before spawning anything, confirm the ref resolves (`git rev-parse <fixed-point>`) and the diff is non-empty - a bad ref or empty diff should fail here, in the open, not inside two sub-agents.

### 2. Find the spec source

Find what the change was *supposed* to do, in this order, resolving the tracker from `.tracker.toml` (see [[tracker-config]]):

1. The **ticket**: an issue reference in the commit messages (`#123`, `Closes #45`) fetched via `gh`, or a `local` ticket under `docs/specs/NNNN-slug/` matching the branch or feature.
2. Its **parent spec** - the ticket names it; read it for the agreed seams and the out-of-scope section.
3. A path the user passed as an argument.
4. If nothing turns up, ask the user where the spec is. If they say there is none, the Spec sub-agent skips and reports "no spec available".

### 3. Find the standards sources

Gather what documents how code should be written *in this repo*: `CODING_STANDARDS.md`, `CONTRIBUTING.md`, or the like, plus the ADRs in the area the diff touches (see [[decision-context]]) - a change that contradicts an accepted ADR is a standards breach. `docs/CONTEXT.md` is the glossary, not a standard, but the Standards axis uses it to judge whether a name matches the project's real vocabulary.

On top of whatever the repo documents, the Standards axis always carries the **smell baseline** below - a fixed set of Fowler code smells (_Refactoring_, ch.3) that applies even when the repo documents nothing. Two rules bind it:

- **The repo overrides.** A documented repo standard or an ADR always wins; where it endorses something the baseline would flag, suppress the smell.
- **Always a judgement call.** Each smell is a labelled heuristic ("possible Feature Envy"), never a hard violation. And skip anything tooling already enforces - lint and formatter findings are not review findings.

Each smell reads *what it is* then *how to fix*; match it against the diff:

- **Mysterious Name**: a function, variable, or type whose name does not reveal what it does or holds. -> rename it; if no honest name comes, the design is murky.
- **Duplicated Code**: the same logic shape appears in more than one hunk or file in the change. -> extract the shared shape, call it from both.
- **Feature Envy**: a method that reaches into another object's data more than its own. -> move the method onto the data it envies.
- **Data Clumps**: the same few fields or params keep travelling together (a type wanting to be born). -> bundle them into one type, pass that.
- **Primitive Obsession**: a primitive or string standing in for a domain concept that deserves its own type. -> give the concept its own small type.
- **Repeated Switches**: the same `switch`/`if`-cascade on the same type recurs across the change. -> replace with polymorphism, or one map both sites share.
- **Shotgun Surgery**: one logical change forces scattered edits across many files in the diff. -> gather what changes together into one module.
- **Divergent Change**: one file or module is edited for several unrelated reasons. -> split so each module changes for one reason.
- **Speculative Generality**: abstraction, parameters, or hooks added for needs the spec does not have. -> delete it; inline back until a real need shows.
- **Message Chains**: long `a.b().c().d()` navigation the caller should not depend on. -> hide the walk behind one method on the first object.
- **Middle Man**: a class or function that mostly just delegates onward. -> cut it, call the real target direct.
- **Refused Bequest**: a subclass or implementer that ignores or overrides most of what it inherits. -> drop the inheritance, use composition.

### 4. Spawn both sub-agents in parallel

Launch both in a single message so they run concurrently, each isolated from the other.

**Standards sub-agent** - give it:

- The full diff command and commit list.
- The standards-source files from step 3, **plus the smell baseline from step 3 pasted in full** (the sub-agent has no other access to it).
- The brief: "Report, per file or hunk where relevant, (a) every place the diff violates a documented repo standard or an accepted ADR - cite the standard (file plus the rule) or the ADR; and (b) any baseline smell you spot - name it and quote the hunk. Distinguish hard violations from judgement calls: documented-standard and ADR breaches can be hard, but baseline smells are always judgement calls, and a documented repo standard or ADR overrides the baseline. Skip anything lint, formatter, or type-checker enforces. Under 400 words."

**Spec sub-agent** - give it:

- The diff command and commit list.
- The ticket and its parent spec (path or fetched contents), including the agreed seams and the out-of-scope section.
- The brief: "Report: (a) requirements the ticket or spec asked for that are missing or partial; (b) behaviour in the diff that was not asked for - scope creep, especially anything the spec's out-of-scope section explicitly refused; (c) requirements that look implemented but where the implementation looks wrong. Quote the ticket or spec line for each finding. Under 400 words."

If there is no spec, skip the Spec sub-agent and say so in the report.

### 5. Aggregate

Present the two reports under `## Standards` and `## Spec` headings, verbatim or lightly cleaned. Do **not** merge or re-rank findings across axes - the separation is the point.

End with a one-line summary: total findings per axis, and the worst issue *within each axis* (if any). Do not pick a single winner across axes; that is the re-ranking the separation exists to prevent.

## Why two axes

A change can pass one axis and fail the other:

- Code that follows every convention but implements the wrong thing -> **Standards pass, Spec fail.**
- Code that does exactly what the ticket asked but breaks the project's conventions -> **Spec pass, Standards fail.**

Reporting them separately stops one axis from masking the other.

## Completion

Done when both axes have reported (or the Spec axis has been recorded as skipped for want of a spec) and the findings are laid out side by side under their own headings, unmerged and un-re-ranked, with the per-axis summary line. Then stop: this skill finds; it does not fix, and it does not review security - hand those to [[tdd]] and [[security-review]] respectively.
