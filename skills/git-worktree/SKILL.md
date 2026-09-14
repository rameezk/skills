---
name: git-worktree
description: Create an isolated Git worktree and do all implementation work there, keeping the user's current working tree and uncommitted changes untouched. Use before making ANY code changes in a Git repository - new features, bug fixes, refactors, tests, or experiments. Skip only when the task is read-only, the user explicitly asks to work in the current checkout, or no Git repository exists.
---

# Git Worktree

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
   - ensure the base branch is up to date
   - a short, descriptive branch name following the `git-branching` skill's naming convention (`<type>/<short-description>`, for example `feat/add-search`, `fix/null-pointer-crash`, `refactor/extract-utils`), unless the repository defines its own naming convention
   - a worktree path inside a `.worktree/` directory at the repository root, named after the branch (for example `.worktree/feat/add-search`)

   Do not fetch, pull, stash, reset, or modify existing changes unless the user explicitly approves it.

3. Ensure `.worktree/` is excluded from Git so the nested worktree never appears as untracked content or is accidentally committed. Use `.git/info/exclude` (local to the clone) rather than the tracked `.gitignore`, so the user's working tree is left untouched:

   ```bash
   exclude_file="$(git rev-parse --git-common-dir)/info/exclude"
   grep -qxF '.worktree/' "$exclude_file" 2>/dev/null || echo '.worktree/' >> "$exclude_file"
   ```

4. If the branch does not exist, create the worktree and branch together:

   ```bash
   git worktree add -b <branch-name> <worktree-path> <base>
   ```

   If the branch already exists and is not checked out elsewhere:

   ```bash
   git worktree add <worktree-path> <branch-name>
   ```

5. Change into the new worktree and verify it before doing any work:

   ```bash
   cd <worktree-path>
   git status --short --branch
   ```

6. Perform all subsequent edits, builds, and tests in the new worktree. Clearly report the worktree path and branch name to the user.

## Cleaning up a worktree

Run cleanup only when the user explicitly asks, and only after confirming the work is preserved (merged, pushed, or explicitly not wanted).

1. Verify the worktree is safe to remove:

   ```bash
   cd <worktree-path>
   git status --short          # should be empty; list anything dirty for the user
   git log <base>..<branch>     # confirm this work is merged or otherwise preserved
   ```

2. Remove the worktree from its parent directory (not from inside it):

   ```bash
   git worktree remove <worktree-path>
   ```

   Git refuses if the worktree is dirty. Never use `--force` without explicit user approval after listing the files that would be lost.

3. Delete the branch only if the work is merged:

   ```bash
   git branch -d <branch-name>
   ```

   `-d` fails safely if the branch is unmerged. Use `-D` only with explicit user approval after showing what would be lost.

4. Prune stale worktree metadata:

   ```bash
   git worktree prune
   ```

## Safety rules

- Never discard, move, or overwrite uncommitted user changes.
- Never reuse a non-empty directory as a new worktree path.
- Do not guess when the correct base branch is materially ambiguous; ask the user.
- Do not remove the worktree or delete its branch automatically. Cleanup requires explicit user approval and must follow the cleanup procedure above, and must happen only after confirming that all wanted work is preserved.
