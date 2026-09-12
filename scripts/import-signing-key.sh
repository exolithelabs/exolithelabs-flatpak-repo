#!/bin/sh
set -eu

if [ -z "${FLATPAK_GPG_PRIVATE_KEY:-}" ]; then
  echo "FLATPAK_GPG_PRIVATE_KEY is not configured." >&2
  exit 1
fi

printf '%s\n' "$FLATPAK_GPG_PRIVATE_KEY" | gpg --batch --import >/dev/null
key_id=$(gpg --batch --with-colons --list-secret-keys | awk -F: '$1 == "sec" { print $5; exit }')
if [ -z "$key_id" ]; then
  echo "No secret signing key was imported." >&2
  exit 1
fi

printf '%s\n' "$key_id"

