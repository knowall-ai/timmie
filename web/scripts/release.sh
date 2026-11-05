#!/usr/bin/env bash
# Bump the web app's version, then make the release commit and tag.
# npm version only commits and tags when package.json is at the git root, and ours is in web/,
# so it bumps the number and this script does the commit and the tag.
# Usage (from web/): bun run release patch|minor|major
set -euo pipefail

bump=${1:?Usage: bun run release patch|minor|major}
cd "$(dirname "$0")/.."

if [ -n "$(git status --porcelain)" ]; then
  echo "Commit or stash your changes before releasing." >&2
  exit 1
fi

tag=$(npm version "$bump" --no-git-tag-version)
git add package.json
git commit -m "chore: release $tag"
git tag -a "$tag" -m "chore: release $tag"
echo "Tagged $tag. Push with: git push && git push --tags"
