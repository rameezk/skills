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

The workflow opens its pull request in one of two ways, depending on how the consuming repo is set up.

### With the default token

Enable **Settings > Actions > General > Allow GitHub Actions to create and approve pull requests**. Nothing else is needed. The sync pull requests are authored by `github-actions[bot]` and do not trigger CI.

Turning that setting on lets any workflow in the repo open and approve pull requests with its default token. To limit that, also set **Settings > Actions > General > Workflow permissions** to **Read repository contents and packages permissions**. The sync workflow asks for the write access it needs, so it keeps working.

### With a skills-sync GitHub App

When the repo has a `skills-sync` environment holding the App's secrets, the workflow opens its pull requests as that App instead. The repo can then keep **Allow GitHub Actions to create and approve pull requests** turned off, so no workflow can approve its own pull request, and the sync pull requests trigger CI like any other. A repo without the App's secrets falls back to the default token. The first run creates an empty `skills-sync` environment in such a repo, which does no harm.

Each account that uses the App path creates its own App, once. It needs only **Contents: Read and write** and **Pull requests: Read and write**, no webhook, and is installable only on the account that owns it. Keep its client ID and private key somewhere you can copy them from, such as a password manager.

### Onboarding a repo to the App

For each repo that should sync its skills as the App:

1. Install the skills with the installer and accept the offer to add `.github/workflows/sync-skills.yml`.
2. Add the repo to the App's installation: **Settings > Applications > Installed GitHub Apps > the App > Configure > Repository access**.
3. Create an environment named `skills-sync` in **Settings > Environments**, and under **Deployment branches and tags** allow only the default branch.
4. Add two environment secrets to `skills-sync`:
   - `SKILLS_SYNC_CLIENT_ID`: the App's client ID.
   - `SKILLS_SYNC_PRIVATE_KEY`: the App's private key, the whole PEM.
5. Run the workflow once with `gh workflow run sync-skills.yml` and check that it opens a pull request authored by the App, or reports that the skills are up to date.

The secrets live in an environment limited to the default branch, not in repository secrets, so a workflow run on any other branch cannot read the App's key.
