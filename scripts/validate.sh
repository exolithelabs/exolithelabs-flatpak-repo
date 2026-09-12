#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_root"

for script in scripts/*.sh; do
  sh -n "$script"
done

if find . -path './.git' -prune -o -type f \( -name '*.private.asc' -o -name '*.secret.asc' -o -name '*.p12' -o -name '*.pfx' \) -print | grep -q .; then
  echo "A private credential-like file is present in the repository." >&2
  exit 1
fi

# shellcheck disable=SC1091
. ./config/repository.env
case "$REPOSITORY_URL" in
  https://*/repo/) ;;
  *) echo "REPOSITORY_URL must be an HTTPS URL ending in /repo/." >&2; exit 1 ;;
esac

for manifest in manifests/*.yml manifests/*.yaml manifests/*.json; do
  [ -e "$manifest" ] || continue
  if command -v flatpak-builder >/dev/null 2>&1; then
    flatpak-builder --show-manifest "$manifest" >/dev/null
  fi
done

echo "Repository configuration is valid."

