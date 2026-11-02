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
# The Linux asset names live only in the formula's url lines; carry them over with the new version.
OLD_ARM_URL="$(awk '/if Hardware::CPU.arm\?/{f=1} f && /^    url /{print; exit}' "${FORMULA}" | sed 's/^    url "\(.*\)"$/\1/')"
OLD_X64_URL="$(awk '/^  else$/{f=1} f && /^    url /{print; exit}' "${FORMULA}" | sed 's/^    url "\(.*\)"$/\1/')"
[[ -n "${OLD_ARM_URL}" && -n "${OLD_X64_URL}" ]] || {
  echo "could not read the arm/x64 urls from ${FORMULA}" >&2
  exit 1
}
LINUX_ARM_URL="${OLD_ARM_URL//"${OLD}"/${NEW}}"
LINUX_X64_URL="${OLD_X64_URL//"${OLD}"/${NEW}}"

BASE="https://github.com/${REPO}/releases/download/v${NEW}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

ARM_SHA="$(fetch_sha "${BASE}/117Terminal-${NEW}-mac-arm64.dmg")"
INTEL_SHA="$(fetch_sha "${BASE}/117Terminal-${NEW}-mac-x64.dmg")"
LINUX_ARM_SHA="$(fetch_sha "${LINUX_ARM_URL}")"
LINUX_X64_SHA="$(fetch_sha "${LINUX_X64_URL}")"

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

# Formula: the url/sha256 pair in the "if Hardware::CPU.arm?" branch and in its "else".
awk -v arm_url="${LINUX_ARM_URL}" -v arm_sha="${LINUX_ARM_SHA}" \
  -v x64_url="${LINUX_X64_URL}" -v x64_sha="${LINUX_X64_SHA}" '
  /if Hardware::CPU.arm\?/ { blk = "arm" }
  /^  else$/ { blk = "x64" }
  blk != "" && /^    url / { sub(/".*"/, "\"" (blk == "arm" ? arm_url : x64_url) "\"") }
  blk != "" && /^    sha256 / { sub(/"[0-9a-f]+"/, "\"" (blk == "arm" ? arm_sha : x64_sha) "\""); blk = "" }
  { print }
' "${FORMULA}" >"${TMP}/rewrite" && cat "${TMP}/rewrite" >"${FORMULA}"

# Make sure every value landed.
grep -q "version \"${NEW}\"" "${CASK}"
grep -q "${ARM_SHA}" "${CASK}"
grep -q "${INTEL_SHA}" "${CASK}"
grep -q "${LINUX_ARM_SHA}" "${FORMULA}"
grep -q "${LINUX_X64_SHA}" "${FORMULA}"
grep -qF "${LINUX_ARM_URL}" "${FORMULA}"
grep -qF "${LINUX_X64_URL}" "${FORMULA}"

echo "Updated to ${NEW}:"
echo "  cask arm64  ${ARM_SHA}"
echo "  cask x64    ${INTEL_SHA}"
echo "  linux arm64 ${LINUX_ARM_SHA}"
echo "  linux x64   ${LINUX_X64_SHA}"
echo "Next: brew style --fix . && git commit -am \"117terminal ${NEW}\""
