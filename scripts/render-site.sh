#!/bin/sh
set -eu

if [ "$#" -ne 3 ]; then
  echo "Usage: render-site.sh <output-directory> <repository-directory> <base64-public-key>" >&2
  exit 1
fi

output_dir=$1
repository_dir=$2
gpg_key=$3
repo_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

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

application_items=$(mktemp)
index_base=$(mktemp)
application_links=$(mktemp)
trap 'rm -f "$application_items" "$index_base" "$application_links"' EXIT HUP INT TERM

escape_html() {
  printf '%s' "$1" | sed \
    -e 's/&/\&amp;/g' \
    -e 's/</\&lt;/g' \
    -e 's/>/\&gt;/g' \
    -e 's/"/\&quot;/g' \
    -e "s/'/\&#39;/g"
}

for template in "$repo_root"/templates/apps/*.flatpakref.in; do
  [ -e "$template" ] || continue
  destination="$output_dir/apps/$(basename "$template" .in)"
  sed \
    -e "s|@REPOSITORY_URL@|$(escape_sed "$REPOSITORY_URL")|g" \
    -e "s|@HOMEPAGE_URL@|$(escape_sed "$HOMEPAGE_URL")|g" \
    -e "s|@REMOTE_NAME@|$(escape_sed "$REMOTE_NAME")|g" \
    -e "s|@GPG_KEY@|$(escape_sed "$gpg_key")|g" \
    "$template" > "$destination"

  app_title=$(sed -n 's/^Title=//p' "$destination" | head -n 1)
  [ -n "$app_title" ] || app_title=$(sed -n 's/^Name=//p' "$destination" | head -n 1)
  app_file=$(basename "$destination")
  printf '        <li><a href="apps/%s">%s</a></li>\n' \
    "$(escape_html "$app_file")" "$(escape_html "$app_title")" >> "$application_items"
done

if [ -s "$application_items" ]; then
  {
    printf '%s\n' '      <section>' '        <h2>Applications</h2>' '        <ul>'
    cat "$application_items"
    printf '%s\n' '        </ul>' '      </section>'
  } > "$application_links"
else
  printf '%s\n' '      <p>No applications are connected yet.</p>' > "$application_links"
fi

sed \
  -e "s|@REPOSITORY_TITLE@|$(escape_sed "$REPOSITORY_TITLE")|g" \
  -e "s|@REPOSITORY_DESCRIPTION@|$(escape_sed "$REPOSITORY_DESCRIPTION")|g" \
  "$repo_root/templates/index.html.in" > "$index_base"

while IFS= read -r line || [ -n "$line" ]; do
  if [ "$line" = '      @APPLICATION_LINKS@' ]; then
    cat "$application_links"
  else
    printf '%s\n' "$line"
  fi
done < "$index_base" > "$output_dir/index.html"

rm -f "$application_items" "$index_base" "$application_links"
trap - EXIT HUP INT TERM
