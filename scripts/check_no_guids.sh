#!/usr/bin/env bash
set -euo pipefail

# Fails if any GUID-like values are present in tracked text files.
# This helps prevent accidentally committing subscription/tenant/object IDs.

GUID_REGEX='[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}'

# Exclude binary files and common generated/vendor content.
# (We intentionally keep this simple and fast.)
mapfile -t files < <(
  find . -type f \
    -not -path './.git/*' \
    -not -path './.terraform/*' \
    -not -path './.github/*/node_modules/*' \
    -not -name '*.png' \
    -not -name '*.jpg' \
    -not -name '*.jpeg' \
    -not -name '*.gif' \
    -not -name '*.pdf' \
    -not -name '*.zip' \
    -not -name '*.tar' \
    -not -name '*.gz' \
    -not -name '*.7z'
)

if [[ ${#files[@]} -eq 0 ]]; then
  exit 0
fi

matches=$(grep -nE "${GUID_REGEX}" "${files[@]}" || true)

if [[ -n "${matches}" ]]; then
  echo "ERROR: Found GUID-like values in repository files."
  echo "Replace them with placeholders (e.g., ##########) or move them to GitHub Secrets/Variables."
  echo ""
  echo "Matches:"
  echo "${matches}"
  exit 1
fi
