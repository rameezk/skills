---
name: new-work
description: Start implementation work in an isolated Git worktree before changing files. Use when beginning a new feature, bug fix, refactor, experiment, or other task that should not disturb the current working tree.
---

# New Work

Create a dedicated Git worktree before making implementation changes. Keep the user's current working tree and any uncommitted changes untouched.

## Use this skill when

- Starting a new feature, bug fix, refactor, or experiment
- The current working tree contains unrelated or uncommitted work
- Multiple tasks need to proceed in parallel
- Isolation makes the work safer or easier to review

## Do not use this skill when

- The task is read-only (for example, explanation, investigation, or code review)
- The user explicitly asks to work in the current checkout
- The current checkout is already a dedicated worktree for this task
- The directory is not in a Git repository
- The requested change depends on uncommitted files in the current worktree; ask the user how to handle that dependency instead

## Workflow

1. Before editing files, inspect the repository:

   ```bash
   git status --short --branch
   git worktree list
   git branch --show-current
   ```

2. Determine:
   - the base commit or branch (use the user's requested base; otherwise infer the repository's normal base branch)
   - a short, descriptive branch name that follows the repository's naming conventions
   - a worktree path outside the current checkout, normally a sibling directory

   Do not fetch, pull, stash, reset, or modify existing changes unless the user explicitly approves it.

3. If the branch does not exist, create the worktree and branch together:

   ```bash
   git worktree add -b <branch-name> <worktree-path> <base>
   ```

   If the branch already exists and is not checked out elsewhere:

   ```bash
   git worktree add <worktree-path> <branch-name>
   ```

4. Change into the new worktree and verify it before doing any work:

   ```bash
   cd <worktree-path>
   git status --short --branch
   ```

5. Perform all subsequent edits, builds, and tests in the new worktree. Clearly report the worktree path and branch name to the user.

## Safety rules

- Never discard, move, or overwrite uncommitted user changes.
- Never reuse a non-empty directory as a new worktree path.
- Do not guess when the correct base branch is materially ambiguous; ask the user.
- Do not remove the worktree or delete its branch automatically. Cleanup requires explicit user approval and must happen only after confirming that all wanted work is preserved.
