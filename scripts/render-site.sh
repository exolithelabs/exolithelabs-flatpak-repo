#!/bin/sh
set -eu

if [ "$#" -ne 3 ]; then
  echo "Usage: render-site.sh <output-directory> <repository-directory> <base64-public-key>" >&2
  exit 1
fi

output_dir=$1
repository_dir=$2
gpg_key=$3
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

# shellcheck disable=SC1091
. "$repo_root/config/repository.env"

escape_sed() {
  printf '%s' "$1" | sed 's/[\\&|]/\\&/g'
}

mkdir -p "$output_dir/apps"
cp -R "$repository_dir" "$output_dir/repo"
touch "$output_dir/.nojekyll"

sed \
  -e "s|@REPOSITORY_TITLE@|$(escape_sed "$REPOSITORY_TITLE")|g" \
  -e "s|@REPOSITORY_URL@|$(escape_sed "$REPOSITORY_URL")|g" \
  -e "s|@HOMEPAGE_URL@|$(escape_sed "$HOMEPAGE_URL")|g" \
  -e "s|@REPOSITORY_COMMENT@|$(escape_sed "$REPOSITORY_COMMENT")|g" \
  -e "s|@REPOSITORY_DESCRIPTION@|$(escape_sed "$REPOSITORY_DESCRIPTION")|g" \
  -e "s|@GPG_KEY@|$(escape_sed "$gpg_key")|g" \
  "$repo_root/templates/exolithelabs.flatpakrepo.in" > "$output_dir/exolithelabs.flatpakrepo"

sed \
  -e "s|@REPOSITORY_TITLE@|$(escape_sed "$REPOSITORY_TITLE")|g" \
  -e "s|@REPOSITORY_DESCRIPTION@|$(escape_sed "$REPOSITORY_DESCRIPTION")|g" \
  "$repo_root/templates/index.html.in" > "$output_dir/index.html"

for template in "$repo_root"/templates/apps/*.flatpakref.in; do
  [ -e "$template" ] || continue
  destination="$output_dir/apps/$(basename "$template" .in)"
  sed \
    -e "s|@REPOSITORY_URL@|$(escape_sed "$REPOSITORY_URL")|g" \
    -e "s|@HOMEPAGE_URL@|$(escape_sed "$HOMEPAGE_URL")|g" \
    -e "s|@REMOTE_NAME@|$(escape_sed "$REMOTE_NAME")|g" \
    -e "s|@GPG_KEY@|$(escape_sed "$gpg_key")|g" \
    "$template" > "$destination"
done

