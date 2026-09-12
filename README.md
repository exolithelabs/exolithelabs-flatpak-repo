# Exolithelabs Flatpak Repository

Shared, GPG-signed Flatpak update repository for public Exolithelabs applications.

This repository owns distribution infrastructure only. Application source code remains in each application's own repository. Add one Flatpak manifest and its referenced metadata per application under `manifests/` when that application is ready to connect.

## Planned public endpoints

- Repository descriptor: `https://exolithelabs.github.io/exolithelabs-flatpak-repo/exolithelabs.flatpakrepo`
- OSTree repository: `https://exolithelabs.github.io/exolithelabs-flatpak-repo/repo/`
- Application references: `https://exolithelabs.github.io/exolithelabs-flatpak-repo/apps/<app>.flatpakref`

Change `REPOSITORY_URL` and `HOMEPAGE_URL` in `config/repository.env` after configuring a custom domain.

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

## Local validation

On Linux with Flatpak Builder installed:

```bash
sh scripts/validate.sh
```

Generated repository data is not committed to `main`. GitHub Pages receives it as a deployment artifact.

## Security

- Only the public key is embedded in published `.flatpakrepo` and `.flatpakref` files.
- The private key exists only in an offline backup and the encrypted GitHub Actions secret.
- Application builds consume pinned, checksummed sources.
- Pull-request workflows validate but never receive the signing secret or publish packages.

## License

The repository tooling and documentation are available under the Apache License 2.0.

