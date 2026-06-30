#!/usr/bin/env bash
set -euo pipefail

repo="${SHANJIAN_CLI_REPO:-shanjian-tv/shanjian-cli}"
version="latest"
install_dir="${HOME}/.local/bin"

usage() {
  cat <<'EOF'
Install the shanjian CLI from GitHub Release binaries.

Usage:
  install-shanjian.sh [--version latest|vX.Y.Z] [--repo owner/name] [--install-dir DIR]

Environment:
  SHANJIAN_CLI_REPO   Default GitHub repo, e.g. shanjian-tv/shanjian-cli
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --version)
      version="${2:?missing value for --version}"
      shift 2
      ;;
    --repo)
      repo="${2:?missing value for --repo}"
      shift 2
      ;;
    --install-dir)
      install_dir="${2:?missing value for --install-dir}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

download() {
  url="$1"
  output="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$output"
    return
  fi
  if command -v wget >/dev/null 2>&1; then
    wget -q "$url" -O "$output"
    return
  fi
  echo "Missing downloader: curl or wget" >&2
  exit 1
}

os="$(uname -s | tr '[:upper:]' '[:lower:]')"
arch="$(uname -m)"

case "$os" in
  darwin|linux) ;;
  *)
    echo "Unsupported OS: $os" >&2
    exit 1
    ;;
esac

case "$arch" in
  x86_64|amd64) arch="amd64" ;;
  arm64|aarch64) arch="arm64" ;;
  *)
    echo "Unsupported architecture: $arch" >&2
    exit 1
    ;;
esac

asset="shanjian_${os}_${arch}.tar.gz"
base_url="https://github.com/${repo}/releases"
if [ "$version" = "latest" ]; then
  asset_url="${base_url}/latest/download/${asset}"
  sums_url="${base_url}/latest/download/SHA256SUMS"
else
  asset_url="${base_url}/download/${version}/${asset}"
  sums_url="${base_url}/download/${version}/SHA256SUMS"
fi

need_cmd tar
need_cmd mkdir
need_cmd chmod

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

archive="${tmp_dir}/${asset}"
extract_dir="${tmp_dir}/extract"
mkdir -p "$extract_dir"

echo "Downloading ${asset_url}"
download "$asset_url" "$archive"

if download "$sums_url" "${tmp_dir}/SHA256SUMS" >/dev/null 2>&1; then
  if grep -F "$asset" "${tmp_dir}/SHA256SUMS" > "${tmp_dir}/SHA256SUMS.one"; then
    if command -v sha256sum >/dev/null 2>&1; then
      (cd "$tmp_dir" && sha256sum -c SHA256SUMS.one)
    elif command -v shasum >/dev/null 2>&1; then
      (cd "$tmp_dir" && shasum -a 256 -c SHA256SUMS.one)
    else
      echo "SHA256SUMS found, but no sha256sum or shasum command is available." >&2
      exit 1
    fi
  fi
else
  echo "SHA256SUMS not available; continuing without checksum verification." >&2
fi

tar -xzf "$archive" -C "$extract_dir"

binary="${extract_dir}/shanjian"
if [ ! -f "$binary" ]; then
  binary="$(find "$extract_dir" -type f -name shanjian -perm -111 | head -n 1)"
fi
if [ -z "${binary:-}" ] || [ ! -f "$binary" ]; then
  echo "Downloaded archive does not contain executable: shanjian" >&2
  exit 1
fi

mkdir -p "$install_dir"
cp "$binary" "${install_dir}/shanjian"
chmod 0755 "${install_dir}/shanjian"

echo "Installed: ${install_dir}/shanjian"
if ! command -v shanjian >/dev/null 2>&1; then
  echo "Add ${install_dir} to PATH before running shanjian." >&2
fi
