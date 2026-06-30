param(
  [string]$Version = "latest",
  [string]$Repo = $(if ($env:SHANJIAN_CLI_REPO) { $env:SHANJIAN_CLI_REPO } else { "shanjian-tv/shanjian-cli" }),
  [string]$InstallDir = (Join-Path $HOME ".local\bin")
)

$ErrorActionPreference = "Stop"

function Fail($Message) {
  Write-Error $Message
  exit 1
}

$arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLowerInvariant()
switch ($arch) {
  "x64" { $arch = "amd64" }
  "x86" { Fail "Unsupported architecture: x86" }
  "arm64" { Fail "Windows arm64 release asset is not available." }
  default { Fail "Unsupported architecture: $arch" }
}

if (-not [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) {
  Fail "Use scripts/install-shanjian.sh on macOS or Linux."
}

$asset = "shanjian_windows_${arch}.zip"
$baseUrl = "https://github.com/$Repo/releases"
if ($Version -eq "latest") {
  $assetUrl = "$baseUrl/latest/download/$asset"
  $sumsUrl = "$baseUrl/latest/download/SHA256SUMS"
} else {
  $assetUrl = "$baseUrl/download/$Version/$asset"
  $sumsUrl = "$baseUrl/download/$Version/SHA256SUMS"
}

$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("shanjian-install-" + [System.Guid]::NewGuid().ToString("N"))
$archive = Join-Path $tempDir $asset
$extractDir = Join-Path $tempDir "extract"
$sumsFile = Join-Path $tempDir "SHA256SUMS"

try {
  New-Item -ItemType Directory -Path $tempDir, $extractDir -Force | Out-Null

  Write-Host "Downloading $assetUrl"
  Invoke-WebRequest -Uri $assetUrl -OutFile $archive

  try {
    Invoke-WebRequest -Uri $sumsUrl -OutFile $sumsFile
    $line = Get-Content $sumsFile | Where-Object { $_ -like "*$asset*" } | Select-Object -First 1
    if ($line) {
      $expected = ($line -split "\s+")[0].ToLowerInvariant()
      $actual = (Get-FileHash -Algorithm SHA256 $archive).Hash.ToLowerInvariant()
      if ($actual -ne $expected) {
        Fail "Checksum mismatch for $asset"
      }
      Write-Host "Checksum verified."
    }
  } catch {
    Write-Warning "SHA256SUMS not available; continuing without checksum verification."
  }

  Expand-Archive -Path $archive -DestinationPath $extractDir -Force
  $binary = Get-ChildItem -Path $extractDir -Recurse -Filter "shanjian.exe" | Select-Object -First 1
  if (-not $binary) {
    Fail "Downloaded archive does not contain shanjian.exe"
  }

  New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
  $target = Join-Path $InstallDir "shanjian.exe"
  Copy-Item $binary.FullName $target -Force

  Write-Host "Installed: $target"
  if (-not (Get-Command shanjian -ErrorAction SilentlyContinue)) {
    Write-Warning "Add $InstallDir to PATH before running shanjian."
  }
} finally {
  if (Test-Path $tempDir) {
    Remove-Item -Recurse -Force $tempDir
  }
}
