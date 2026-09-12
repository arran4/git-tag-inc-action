#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-latest}"
GITHUB_TOKEN="${2:-}"
REF="${3:-}"
EXPECTED_SHA256="${4:-}"

echo "Starting git-tag-inc setup..."
echo "Requested version: $VERSION"
if [ -n "$REF" ]; then
  echo "Requested ref: $REF"
fi

if [ -n "$REF" ]; then
  if ! command -v go >/dev/null 2>&1; then
    echo "Error: The 'go' command is required to build from a ref, but it was not found in PATH."
    exit 1
  fi

  echo "Building git-tag-inc from source using go install github.com/arran4/git-tag-inc/...@$REF"
  go install "github.com/arran4/git-tag-inc/...@$REF"

  GOPATH=$(go env GOPATH)
  if [ -z "$GOPATH" ]; then
    GOPATH="$HOME/go"
  fi
  GOBIN=$(go env GOBIN)
  if [ -z "$GOBIN" ]; then
    GOBIN="$GOPATH/bin"
  fi

  if [ -n "${GITHUB_PATH:-}" ]; then
    echo "$GOBIN" >> "$GITHUB_PATH"
    echo "Added $GOBIN to GITHUB_PATH"
  else
    echo "Warning: GITHUB_PATH is not set. Assuming local run."
    export PATH="$GOBIN:$PATH"
  fi

  echo "Successfully installed git-tag-inc from ref $REF"
  "$GOBIN/git-tag-inc" lint --help >/dev/null
  exit 0
fi

# Detect OS
OS="linux"
if [ "${RUNNER_OS:-}" = "macOS" ]; then
  OS="darwin"
elif [ "${RUNNER_OS:-}" = "Windows" ]; then
  OS="windows"
fi

# Detect Architecture
ARCH="amd64"
if [ "${RUNNER_ARCH:-}" = "ARM64" ]; then
  ARCH="arm64"
elif [ "${RUNNER_ARCH:-}" = "ARM32" ]; then
  ARCH="armv7"
fi

echo "Detected OS: $OS"
echo "Detected Arch: $ARCH"

# Fetch release info
if [ "$VERSION" = "latest" ]; then
  API_URL="https://api.github.com/repos/arran4/git-tag-inc/releases/latest"
else
  API_URL="https://api.github.com/repos/arran4/git-tag-inc/releases/tags/${VERSION}"
fi

echo "Fetching release info from: $API_URL"

CURL_ARGS=(-sL)
if [ -n "$GITHUB_TOKEN" ]; then
  CURL_ARGS+=(-H "Authorization: Bearer $GITHUB_TOKEN")
fi

# Use curl to get release JSON
RELEASE_JSON=$(curl "${CURL_ARGS[@]}" "$API_URL")

# Basic check for Not Found
if echo "$RELEASE_JSON" | grep -q '"message": "Not Found"'; then
  echo "Error: Release not found. Please check the version."
  exit 1
fi

# Extract tag_name using grep to avoid perl regex if grep doesn't support -P everywhere
TAG_NAME=$(echo "$RELEASE_JSON" | grep '"tag_name":' | head -n 1 | sed -E 's/.*"tag_name": "([^"]+)".*/\1/')

if [ -z "$TAG_NAME" ]; then
  echo "Error: Could not parse tag_name from release info."
  exit 1
fi

echo "Found release tag: $TAG_NAME"

# Determine download URL
VERSION_WITHOUT_V="${TAG_NAME#v}"

FILE_EXT="tar.gz"
if [ "$OS" = "windows" ]; then
  FILE_EXT="zip"
fi

FILENAME="git-tag-inc_${VERSION_WITHOUT_V}_${OS}_${ARCH}.${FILE_EXT}"
DOWNLOAD_URL="https://github.com/arran4/git-tag-inc/releases/download/${TAG_NAME}/${FILENAME}"

echo "Downloading from: $DOWNLOAD_URL"
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT
cd "$TEMP_DIR"

# Download the file
curl -sL -f -o "$FILENAME" "$DOWNLOAD_URL" || {
  echo "Error: Failed to download $DOWNLOAD_URL"
  exit 1
}

echo "Download successful."

# Release-critical callers can pin the expected digest so the downloaded
# archive is verified independently of mutable release metadata.
if [ -n "$EXPECTED_SHA256" ]; then
  if ! [[ "$EXPECTED_SHA256" =~ ^[0-9a-fA-F]{64}$ ]]; then
    echo "Error: sha256 must be exactly 64 hexadecimal characters."
    exit 1
  fi

  if command -v sha256sum >/dev/null 2>&1; then
    printf '%s  %s\n' "$EXPECTED_SHA256" "$FILENAME" | sha256sum -c -
  elif command -v shasum >/dev/null 2>&1; then
    ACTUAL_SHA256=$(shasum -a 256 "$FILENAME" | awk '{print $1}')
    EXPECTED_SHA256_LOWER=$(printf '%s' "$EXPECTED_SHA256" | tr '[:upper:]' '[:lower:]')
    if [ "$ACTUAL_SHA256" != "$EXPECTED_SHA256_LOWER" ]; then
      echo "Error: SHA256 mismatch for $FILENAME."
      echo "Expected: $EXPECTED_SHA256"
      echo "Actual:   $ACTUAL_SHA256"
      exit 1
    fi
    echo "$FILENAME: OK"
  else
    echo "Error: Cannot verify SHA256 because neither sha256sum nor shasum is available."
    exit 1
  fi
else
  echo "Warning: no expected SHA256 supplied; archive integrity is not independently pinned."
fi

# Extract and install
INSTALL_DIR="/opt/git-tag-inc"
if [ "$OS" = "windows" ]; then
  # On Windows runners, using Git Bash means /c/ is usually C:\
  INSTALL_DIR="/c/git-tag-inc"
  mkdir -p "$INSTALL_DIR"
else
  sudo mkdir -p "$INSTALL_DIR"
fi

echo "Extracting archive to $INSTALL_DIR..."
if [ "$OS" = "windows" ]; then
  unzip -q "$FILENAME" -d "$INSTALL_DIR"
else
  sudo tar -xzf "$FILENAME" -C "$INSTALL_DIR"
fi

# Make binary executable
if [ "$OS" != "windows" ]; then
  sudo chmod +x "$INSTALL_DIR/git-tag-inc"
fi

# Add to GITHUB_PATH
if [ -n "${GITHUB_PATH:-}" ]; then
  echo "$INSTALL_DIR" >> "$GITHUB_PATH"
  echo "Added $INSTALL_DIR to GITHUB_PATH"
else
  echo "Warning: GITHUB_PATH is not set. Assuming local run."
  export PATH="$INSTALL_DIR:$PATH"
fi

echo "Successfully installed git-tag-inc $TAG_NAME"
"$INSTALL_DIR/git-tag-inc" lint --help >/dev/null
