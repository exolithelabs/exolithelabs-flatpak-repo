#!/bin/sh
set -eu

if [ "$#" -ne 4 ]; then
  echo "Usage: update-resume-builder-release.sh <commit> <tag> <version> <date>" >&2
  exit 1
fi

source_commit=$1
release_tag=$2
release_version=$3
release_date=$4
source_url=https://github.com/exolithelabs/resume-builder.git
manifest=manifests/io.github.exolithelabs.ResumeBuilder.yml
metainfo=metadata/io.github.exolithelabs.ResumeBuilder.metainfo.xml

case "$source_commit" in
  *[!0-9a-f]*|'') echo "Source commit must be a lowercase hexadecimal Git commit." >&2; exit 1 ;;
esac
[ "${#source_commit}" -eq 40 ] || { echo "Source commit must contain 40 characters." >&2; exit 1; }

printf '%s\n' "$release_version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+([+-][0-9A-Za-z.-]+)?$' || {
  echo "Release version must be a semantic version." >&2
  exit 1
}
[ "$release_tag" = "v$release_version" ] || { echo "Release tag and version do not match." >&2; exit 1; }

case "$release_date" in
  ????-??-??) ;;
  *) echo "Release date must use YYYY-MM-DD." >&2; exit 1 ;;
esac

remote_refs=$(git ls-remote --tags "$source_url" "refs/tags/$release_tag" "refs/tags/$release_tag^{}")
peeled_commit=$(printf '%s\n' "$remote_refs" | awk '$2 ~ /\^\{\}$/ { print $1; exit }')
direct_commit=$(printf '%s\n' "$remote_refs" | awk '$2 !~ /\^\{\}$/ { print $1; exit }')
remote_commit=${peeled_commit:-$direct_commit}

[ -n "$remote_commit" ] || { echo "Release tag does not exist in the Resume Builder repository." >&2; exit 1; }
[ "$remote_commit" = "$source_commit" ] || { echo "Release tag does not point to the supplied commit." >&2; exit 1; }

sed -i -E "s|^([[:space:]]*commit: )[0-9a-f]{40}$|\1$source_commit|" "$manifest"
grep -Fq "commit: $source_commit" "$manifest" || { echo "Could not update the manifest commit." >&2; exit 1; }

if ! grep -Fq "<release version=\"$release_version\"" "$metainfo"; then
  sed -i "/  <releases>/a\\    <release version=\"$release_version\" date=\"$release_date\" />" "$metainfo"
fi

echo "Resume Builder $release_tag is pinned to $source_commit."
