# AGENTS.md — Exolithe Labs Flatpak Repository

This repository is the shared Flatpak distribution and update infrastructure for Exolithe Labs applications. It does not contain application source code.

## Boundaries

- Keep application source in its application repository.
- Keep one manifest and metadata set per connected application.
- Never commit private keys, passphrases, tokens, generated repository objects, user data, or unpinned remote sources.
- `main` stores infrastructure, manifests, templates, and public metadata only.
- GitHub Pages receives generated OSTree repository files through Actions.
- All published application commits and repository summaries must be signed with the dedicated Flatpak key.
- Pull requests may validate but must never sign or deploy.

## Release model

1. An application publishes immutable, checksummed release inputs.
2. A trusted release dispatch verifies the source tag and updates its pinned manifest, or the manifest is updated manually.
3. CI builds x86_64 and aarch64 repository fragments on native runners.
4. The publish job combines, signs, and deploys one shared repository.
5. `.flatpakref` files point users to that repository for future updates.

Resume Builder release tags automatically dispatch their exact commit and version to the publish workflow. Keep `workflow_dispatch` available as a manual recovery path.

Run `sh scripts/validate.sh` before committing changes.
