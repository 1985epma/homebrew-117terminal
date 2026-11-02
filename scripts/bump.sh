#!/usr/bin/env bash
# Update the cask and formula to a released version of 117Terminal.
#
#   scripts/bump.sh 0.1.1
#
# Downloads the release assets from GitHub (1985epma/117-terminal, tag v<version>), computes their
# sha256 and rewrites version, URLs and sha256 in Casks/117terminal.rb and Formula/terminal117.rb.
# Needs curl and shasum (macOS) or sha256sum (Linux). The release must already be published.
set -euo pipefail

REPO="1985epma/117-terminal"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CASK="${ROOT}/Casks/117terminal.rb"
FORMULA="${ROOT}/Formula/terminal117.rb"

usage() {
  echo "usage: $0 <version>   (e.g. $0 0.1.1)" >&2
  exit 2
}

[[ $# -eq 1 ]] || usage
NEW="${1#v}"
[[ "${NEW}" =~ ^[0-9]+(\.[0-9]+)*$ ]] || usage

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1
  then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

# Downloads a URL into the temp dir and prints its sha256.
fetch_sha() {
  local url="$1" file
  file="${TMP}/$(basename "${url}")"
  echo "Downloading ${url}" >&2
  curl -fsSL --retry 3 -o "${file}" "${url}" || {
    echo "download failed: ${url} (is the release published?)" >&2
    exit 1
  }
  sha256_of "${file}"
}

# Current values, read from the files themselves.
OLD="$(sed -n 's/^  version "\(.*\)"$/\1/p' "${CASK}")"
[[ -n "${OLD}" ]] || {
  echo "could not read the version from ${CASK}" >&2
  exit 1
}
# The Linux asset name lives only in the formula's url line; carry it over with the new version.
OLD_LINUX_URL="$(sed -n 's/^  url "\(.*\)"$/\1/p' "${FORMULA}")"
[[ -n "${OLD_LINUX_URL}" ]] || {
  echo "could not read the url from ${FORMULA}" >&2
  exit 1
}
LINUX_URL="${OLD_LINUX_URL//"${OLD}"/${NEW}}"

BASE="https://github.com/${REPO}/releases/download/v${NEW}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

ARM_SHA="$(fetch_sha "${BASE}/117Terminal-${NEW}-mac-arm64.dmg")"
INTEL_SHA="$(fetch_sha "${BASE}/117Terminal-${NEW}-mac-x64.dmg")"
LINUX_SHA="$(fetch_sha "${LINUX_URL}")"

# Rewrite in place (portable between BSD and GNU sed: write to a temp file, then move).
rewrite() {
  local file="$1" script="$2"
  sed -E "${script}" "${file}" >"${TMP}/rewrite" && cat "${TMP}/rewrite" >"${file}"
}

rewrite "${CASK}" "
s/^  version \".*\"$/  version \"${NEW}\"/
s/^  sha256 arm: +\"[0-9a-f]{64}\",$/  sha256 arm:   \"${ARM_SHA}\",/
s/^         intel: \"[0-9a-f]{64}\"$/         intel: \"${INTEL_SHA}\"/
"

rewrite "${FORMULA}" "
s|^  url \".*\"$|  url \"${LINUX_URL}\"|
s/^  sha256 \"[0-9a-f]{64}\"$/  sha256 \"${LINUX_SHA}\"/
"

# Make sure every value landed.
grep -q "version \"${NEW}\"" "${CASK}"
grep -q "${ARM_SHA}" "${CASK}"
grep -q "${INTEL_SHA}" "${CASK}"
grep -q "${LINUX_SHA}" "${FORMULA}"
grep -qF "${LINUX_URL}" "${FORMULA}"

echo "Updated to ${NEW}:"
echo "  cask arm64  ${ARM_SHA}"
echo "  cask x64    ${INTEL_SHA}"
echo "  linux x64   ${LINUX_SHA}"
echo "Next: brew style --fix . && git commit -am \"117terminal ${NEW}\""
