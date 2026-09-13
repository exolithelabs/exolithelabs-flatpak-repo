#!/bin/sh
set -eu

identity="${FLATPAK_GPG_IDENTITY:-Exolithe Labs Flatpak Repository}"
output="${1:-exolithelabs-flatpak-private.asc}"

if ! command -v gpg >/dev/null 2>&1; then
  echo "GnuPG is required." >&2
  exit 1
fi

if [ -e "$output" ]; then
  echo "Refusing to overwrite $output" >&2
  exit 1
fi

echo "Creating a dedicated Ed25519 signing key for: $identity"
gpg --batch --passphrase '' --quick-generate-key "$identity" ed25519 sign 0
key_id=$(gpg --batch --with-colons --list-secret-keys "$identity" | awk -F: '$1 == "sec" { print $5; exit }')
if [ -z "$key_id" ]; then
  echo "The signing key could not be identified." >&2
  exit 1
fi

gpg --batch --armor --output "$output" --export-secret-keys "$key_id"
gpg --batch --armor --output exolithelabs-flatpak-public.asc --export "$key_id"

echo "Created signing key $key_id"
echo "Private export: $output (back up securely; never commit)"
echo "Public export:  exolithelabs-flatpak-public.asc (safe to share)"
echo "GitHub secret:  FLATPAK_GPG_PRIVATE_KEY"
