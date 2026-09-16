---
name: to-spec
description: Turn a refined piece of work into a spec - a durable record of what was decided and why - and publish it to the configured tracker. Use once shared understanding is reached and the plan needs to survive being split across sessions.
disable-model-invocation: true
---

# To Spec

Turn the conversation into a **spec**: a record of the decisions already made, in the project's own language, written to survive a context clear and be picked up by a fresh session.

By the time this runs, [[refine]] has done the deciding. Do not interview the user and do not reopen questions - synthesize what is already settled. The spec decides nothing; it captures what was decided. Anything the spec asserts that was never actually agreed is a defect.

## How it works

1. **Read the tracker config.** Look for `.tracker.toml` at the project root. It names where specs go:

   ```toml
   type = "local"        # or "github"
   # repo = "owner/name" # required when type = "github"
   ```

   If no `.tracker.toml` exists, stop and tell the user to create one with the two lines above rather than guessing a destination.

2. **Explore the repo.** Ground the spec in how the code actually works, and speak in the project's vocabulary - use the terms from `docs/CONTEXT.md` and respect the ADRs in the area you're touching (see [[decision-context]]). Delegate the digging to a subagent rather than asking the user what you can check yourself.

3. **Sketch the seams, then confirm.** A **seam** is a place where you can alter behaviour without editing in that place (Michael Feathers, *Working Effectively with Legacy Code*) - the boundary a test plugs into. Propose the seams the feature will be tested at: prefer seams that already exist, take the highest seam you can, and aim for the fewest possible - ideally one across the whole change. Put the proposed seams to the user and hold for sign-off before writing a word.

4. **Write the spec** using the scaffold in [`spec-template.md`](spec-template.md). Decisions, not implementation: no file paths and no code snippets - they go stale fast. A durable, hard-to-reverse decision belongs in an ADR via [[decision-context]]; reference it from the spec rather than restating it.

5. **Publish** to the destination from the config:
   - **local** - write to `docs/specs/NNNN-slug.md`. Number sequentially with 4-digit zero-padding: scan the directory for the highest existing number and add one, starting at `0001` if it is empty.
   - **github** - publish as a single issue on `repo` via `gh`. Title the issue with the feature name and apply a `spec` label, so a fresh session can find it again with `gh issue list --label spec`. The issue URL is the spec's identity - GitHub assigns the number, so there is no `NNNN` to manage here.

## Completion

The spec is done when every decision in it is one the user can remember making, the out-of-scope section names the things that were deliberately refused, and the agreed seams are recorded. Stop there. This skill records the plan; it does not build it, and it does not slice it into tickets.
