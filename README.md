# skills

## Install

### Nix

```bash
nix run github:rameezk/skills#install
```

### Bash

```bash
curl -fsSL https://raw.githubusercontent.com/rameezk/skills/main/install.sh | bash
```

## Keeping skills up to date

The installer offers to add `.github/workflows/sync-skills.yml` to the consuming repo. This runs a scheduled check for any skill updates.

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

The workflow can only open pull requests once **Settings > Actions > General > Allow GitHub Actions to create and approve pull requests** is enabled in the consuming repo.

Turning that on lets any workflow in the repo open and approve pull requests with its default token. To limit that, also set **Settings > Actions > General > Workflow permissions** to **Read repository contents and packages permissions**. The sync workflow asks for the write access it needs, so it keeps working, while other workflows only get write access if they ask for it too.
