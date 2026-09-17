---
name: work-on
description: Work on a single frontier ticket end-to-end - in an isolated worktree, test-first, committed, and raised as a PR. Use to dispatch one ready ticket from the task graph into working, reviewable code. This is the dispatch step [[to-tickets]] hands off to.
disable-model-invocation: true
---

# Work On

Take one ticket from the frontier and drive it all the way to an open pull request: isolate the work in its own worktree, build it test-first, commit it, and raise the PR. One ticket, one fresh session - the unit [[to-tickets]] cut the plan into.

This skill dispatches a ticket; it does not decide what to build. The deciding happened upstream in [[refine]], the recording in [[to-spec]], the slicing in [[to-tickets]]. Do not reopen any of it. If the ticket is ambiguous enough that you would have to invent a decision, stop and send the user back to [[refine]] rather than guessing here.

## Pick a frontier ticket

Work only the **frontier** - a ticket whose status is not `done` and every ticket it is blocked by *is* `done`. Take the ticket the user names; if they name one that is still blocked, say which blockers are open and stop. If they name none, resolve the tracker and surface the frontier for them to pick from - do not grab one silently.

Resolve the tracker from `.tracker.toml` at the project root (see [[tracker-config]]): `local` tickets live under `docs/specs/NNNN-slug/`, `github` tickets are issues found via `gh issue list`. If the file is missing or malformed, hand off to [[tracker-config]] rather than guessing where work is tracked.

## The recipe

Run these in order. Each step is its own skill; drive them, do not reimplement them.

1. **Read the ticket - and its parent spec.** Read the whole ticket: what it delivers, its blocking edges, whether it is `ready-for-agent` or `ready-for-human`. Then read its parent spec for the two things the ticket leans on but does not repeat: the **agreed seams** and the **out-of-scope** section. Building something the spec explicitly refused is a defect, not initiative. Ground yourself in how the code actually works and speak its language - read `docs/CONTEXT.md` for vocabulary and respect the ADRs in the area you are touching (see [[decision-context]]).

   If the ticket is `ready-for-human`, it reached the frontier because it turns on a call an agent should not make alone, a manual or external step, or a change too risky to hand off. Do not build it unattended - surface why it is human-flagged and confirm with the user before going further.

2. **Isolate the work.** Create a dedicated worktree with [[git-worktree]], branched off up-to-date default, so the work never lands on the user's current checkout or on stale state. All subsequent edits, tests, and commits happen there.

3. **Build it test-first.** Implement the ticket through [[tdd]]. Its precondition is agreed seams: restate the seams the spec settled and confirm them before the first test; if the spec left them open, settle them with the user here, before any test. Then work the red-green-refactor loop in vertical slices - one behaviour at a time, consolidating each slice as you go. Run single test files as you work and the full suite once at the end; report that final run. Leave feature-wide consolidation and cross-cutting refactors for review, as [[tdd]] says.

4. **Review - before committing.** Put the finished change through two independent reviews, run in **separate sub-agents launched in one message** so they go concurrently in isolated contexts, each with fresh eyes on code this session is biased toward: [[code-review]] for standards and spec conformance, and [[security-review]] for vulnerabilities. Run both reviews on the **code diff** - the change in the worktree measured against the branch's base, including work not yet committed - not on the whole repo, and both are strictly read-only. Collect both reports, then triage as the orchestrator: fix real findings *before* committing, and fixing means going back through a fresh [[tdd]] cycle, not a patch that skips the loop. For a finding you judge not worth acting on, say which and why - do not silently drop it. If the fixes are substantial, re-run the affected review.

5. **Commit.** Once the reviews are addressed and the suite is green, record the work with [[git-committing]] - focused commits, Conventional Commits, on the worktree's branch. Only now, not before review.

6. **Open the PR.** Raise the pull request with [[git-pr]]. Link it to the originating ticket so merging it closes the ticket: on `github`, reference the issue with `Closes #N` in the description. Ground the description in the ticket - what it delivered and how it was verified.

## What this skill does not do

- **It does not mark the ticket done.** The ticket closes when its PR is *merged*, not when the PR is opened - on `github` the `Closes #N` link does this automatically on merge. Do not flip ticket status here.
- **It does not work more than one ticket.** If finishing this ticket clears blockers and opens new frontier tickets, that is the next dispatch - a fresh session, a fresh run of this skill - not more work piled onto this one.

## Completion

Done when the ticket's behaviour is built, both reviews have run on the diff and their findings are addressed, the full suite is green on a real run, the work is committed in its own worktree branch, and the PR is open and linked to the ticket. Report the worktree path, the branch, the final test run, how the review findings were handled, and the PR URL. Then stop: the ticket is not yours to close, and the next ticket is not yours to start.
