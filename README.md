# skills

## Install

Run the installer from the root of the repo that should get the skills.

### Nix

```bash
nix run github:rameezk/skills#install
```

### Bash

```bash
curl -fsSL https://raw.githubusercontent.com/rameezk/skills/main/install.sh | bash
```

The installer copies the chosen skills into `.agents/skills`, links them for your harness, and records what it installed and from which commit in `.agents/skills.lock`. Commit all of it.

## Keeping skills up to date

The installer offers to add `.github/workflows/sync-skills.yml` to the consuming repo. Every Monday it re-copies the skills listed in `.agents/skills.lock` from `main` and opens a `chore: sync skills` pull request when any of them changed. The pull request lists the commits that touched those skills. Skills deleted here are removed from the consuming repo in the same pull request.

To update right away, run the workflow from the consuming repo's Actions tab, or with:

```bash
gh workflow run sync-skills.yml
gh workflow run sync-skills.yml -f ref=some-branch
```

To update locally instead, run the installer with `--sync`:

```bash
nix run github:rameezk/skills#install -- --sync
curl -fsSL https://raw.githubusercontent.com/rameezk/skills/main/install.sh | bash -s -- --sync
```

### Repo settings

- Enable **Settings > Actions > General > Allow GitHub Actions to create and approve pull requests**.
- Pull requests opened with the default `GITHUB_TOKEN` do not trigger other workflows, so CI will not run on them. To get CI, add a `SKILLS_SYNC_TOKEN` secret holding a fine-grained token with contents and pull request write access to the repo.
