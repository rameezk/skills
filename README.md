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

### The skills-sync GitHub App

The workflow opens its pull requests as a GitHub App, not with the repo's default token. The repo can then keep **Settings > Actions > General > Allow GitHub Actions to create and approve pull requests** turned off, so no workflow can approve its own pull request, and the sync pull requests trigger CI like any other.

The App is created once per account. It needs only **Contents: Read and write** and **Pull requests: Read and write**, no webhook, and is installable only on the account that owns it. Keep its client ID and private key somewhere you can copy them from, such as a password manager.

### Onboarding a repo

For each repo that should sync its skills:

1. Install the skills with the installer and accept the offer to add `.github/workflows/sync-skills.yml`.
2. Add the repo to the App's installation: **Settings > Applications > Installed GitHub Apps > the App > Configure > Repository access**.
3. Create an environment named `skills-sync` in **Settings > Environments**, and under **Deployment branches and tags** allow only the default branch.
4. Add two environment secrets to `skills-sync`:
   - `SKILLS_SYNC_CLIENT_ID`: the App's client ID.
   - `SKILLS_SYNC_PRIVATE_KEY`: the App's private key, the whole PEM.
5. Run the workflow once with `gh workflow run sync-skills.yml` and check that it opens a pull request authored by the App, or reports that the skills are up to date.

The secrets live in an environment limited to the default branch, not in repository secrets, so a workflow run on any other branch cannot read the App's key.
