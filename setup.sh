#!/usr/bin/env bash
set -e

VERSION="${1:-latest}"
GITHUB_TOKEN="${2}"
REF="${3}"

echo "Starting git-tag-inc setup..."
echo "Requested version: $VERSION"
if [ -n "$REF" ]; then
  echo "Requested ref: $REF"
fi

if [ -n "$REF" ]; then
  echo "Building git-tag-inc from source using go install github.com/arran4/git-tag-inc/...@$REF"
  go install github.com/arran4/git-tag-inc/...@$REF

  GOPATH=$(go env GOPATH)
  if [ -z "$GOPATH" ]; then
    GOPATH="$HOME/go"
  fi
  GOBIN=$(go env GOBIN)
  if [ -z "$GOBIN" ]; then
    GOBIN="$GOPATH/bin"
  fi

  if [ -n "$GITHUB_PATH" ]; then
    echo "$GOBIN" >> "$GITHUB_PATH"
    echo "Added $GOBIN to GITHUB_PATH"
  else
    echo "Warning: GITHUB_PATH is not set. Assuming local run."
    export PATH="$GOBIN:$PATH"
  fi

  echo "Successfully installed git-tag-inc from ref $REF"
  "$GOBIN/git-tag-inc" --help || true
  exit 0
fi

# Detect OS
OS="linux"
if [ "$RUNNER_OS" = "macOS" ]; then
  OS="darwin"
elif [ "$RUNNER_OS" = "Windows" ]; then
  OS="windows"
fi

# Detect Architecture
ARCH="amd64"
if [ "$RUNNER_ARCH" = "ARM64" ]; then
  ARCH="arm64"
elif [ "$RUNNER_ARCH" = "ARM32" ]; then
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
cd "$TEMP_DIR"

# Download the file
curl -sL -f -o "$FILENAME" "$DOWNLOAD_URL" || {
  echo "Error: Failed to download $DOWNLOAD_URL"
  exit 1
}

echo "Download successful."

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
if [ -n "$GITHUB_PATH" ]; then
  echo "$INSTALL_DIR" >> "$GITHUB_PATH"
  echo "Added $INSTALL_DIR to GITHUB_PATH"
else
  echo "Warning: GITHUB_PATH is not set. Assuming local run."
  export PATH="$INSTALL_DIR:$PATH"
fi

echo "Successfully installed git-tag-inc $TAG_NAME"
"$INSTALL_DIR/git-tag-inc" --help || true
