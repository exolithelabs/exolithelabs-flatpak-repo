# Exolithe Labs Flatpak Repository

Shared, GPG-signed Flatpak update repository for public Exolithe Labs applications.

This repository owns distribution infrastructure only. Application source code remains in each application's own repository. Add one Flatpak manifest and its referenced metadata per application under `manifests/` when that application is ready to connect.

## Planned public endpoints (GitHub Pages)

- Repository descriptor: `https://flatpak.exolithelabs.com/exolithelabs.flatpakrepo`
- OSTree repository: `https://flatpak.exolithelabs.com/repo/`
- Application references: `https://flatpak.exolithelabs.com/apps/<app>.flatpakref`

GitHub Pages uses `flatpak.exolithelabs.com` as its custom domain with HTTPS enforced.

This repository is deployed to GitHub Pages. The deployed Flatpak files must remain publicly readable for anonymous installation and updates.

## Initial setup

1. Create the public GitHub repository and push this checkout:

   ```bash
   gh repo create exolithelabs/exolithelabs-flatpak-repo \
     --public --source=. --remote=origin --push
   ```

2. On a trusted Linux machine, create the dedicated signing key:

   ```bash
   sh scripts/create-signing-key.sh
   ```

   Back up the generated private-key file somewhere secure, then add its complete armored contents as the GitHub Actions secret `FLATPAK_GPG_PRIVATE_KEY`. Delete the exported private-key file from the working directory after the secret and backup have been verified. Never commit it.

3. In **GitHub repository → Settings → Pages**, select **GitHub Actions** as the publishing source.

4. Add at least one application manifest under `manifests/` and its `.flatpakref.in` template under `templates/apps/`.

5. Run **Publish Flatpak repository** manually from the Actions tab. The workflow builds on native x86_64 and ARM64 runners, signs both commits, combines them into one repository, and deploys the static result to GitHub Pages.

The publish workflow intentionally refuses to run with no application manifests or without the signing-key secret.

## Adding an application later

Add these files in one commit:

```text
manifests/com.exolithelabs.Example.yml
metadata/com.exolithelabs.Example.metainfo.xml
metadata/com.exolithelabs.Example.desktop
templates/apps/com.exolithelabs.Example.flatpakref.in
```

The application manifest must pin every downloaded source by commit/version and checksum. It must also support both `x86_64` and `aarch64`, or explicitly document a supported-architecture restriction before the matrix is changed.

Resume Builder is built from an immutable source commit using the GNOME SDK with its Node 20 and Rust extensions. The self-hosted build currently permits dependency downloads from the lockfiles during the build; future releases can replace this with generated offline npm and Cargo source lists.

## Local validation

On Linux with Flatpak Builder installed:

```bash
sh scripts/validate.sh
```

Generated repository data is not committed to `main`. GitHub Pages receives it as a deployment artifact.
The published homepage automatically lists every application reference found under `templates/apps/`.

## Connected applications

### Resume Builder

Install from the published reference:

```bash
flatpak install --from https://flatpak.exolithelabs.com/apps/io.github.exolithelabs.ResumeBuilder.flatpakref
```

Run it with:

```bash
flatpak run io.github.exolithelabs.ResumeBuilder
```

## Security

- Only the public key is embedded in published `.flatpakrepo` and `.flatpakref` files.
- The private key exists only in an offline backup and the encrypted GitHub Actions secret.
- Application builds consume pinned, checksummed sources.
- Pull-request workflows validate but never receive the signing secret or publish packages.

## License

The repository tooling and documentation are available under the Apache License 2.0.
