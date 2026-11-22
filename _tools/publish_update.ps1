# _tools/publish_update.ps1
#
# 一条命令完成「构建 → 计算 sha256 → 写 update/latest.json → 拷贝到 NASHub 目录」。
#
# 用法（在本机跑）：
#   powershell -ExecutionPolicy Bypass -File _tools/publish_update.ps1 `
#       -Version 1.1.0 -Notes "修复补记日期限制" `
#       -NasDir "Z:\nashub\yueji" `
#       -GitHubRepo "yourname/cycle_note"
#
# 说明：
#   · GitHub 路径只写 update/latest.json 里的 apkUrl；真正的上传用 `gh release create`
#     （脚本会提示命令，不替你 push，避免误发）；
#   · NASHub 路径是把 APK + latest.json 拷到 NAS 挂载目录（SMB 映射成盘符即可），
#     静态服务指向该目录，URL 就是 https://<nas>/nashub/yueji/latest.json。
#
# 兼容 Windows PowerShell 5.1（UTF-8 BOM 保存）。

param(
    [Parameter(Mandatory = $true)][string]$Version,
    [string]$Notes = '',
    [string]$NasDir = '',
    [string]$GitHubRepo = 'YOUR_GITHUB/cycle_note',
    [string]$NasBaseUrl = 'https://YOUR_NAS_DOMAIN/nashub/yueji'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if (-not $env:GRADLE_USER_HOME) { $env:GRADLE_USER_HOME = Join-Path $env:USERPROFILE 'GradleHome-yueji' }

$ver = $Version.TrimStart('v', 'V')

Write-Output "==> 构建 release APK ($ver)"
Push-Location $root
flutter build apk --release --target-platform android-arm64 `
    --dart-define=APP_VERSION=$ver
if ($LASTEXITCODE -ne 0) { Pop-Location; throw '构建失败' }
Pop-Location

$apk = Join-Path $root 'build\app\outputs\flutter-apk\app-release.apk'
if (-not (Test-Path $apk)) { throw "找不到产物：$apk" }

$assetName = "yueji-$ver-arm64.apk"
$distDir = Join-Path $root 'dist'
if (-not (Test-Path $distDir)) { New-Item -ItemType Directory -Path $distDir | Out-Null }
$distApk = Join-Path $distDir $assetName
Copy-Item $apk $distApk -Force

$hash = (Get-FileHash $distApk -Algorithm SHA256).Hash.ToLower()
$size = (Get-Item $distApk).Length
Write-Output "==> sha256=$hash size=$size"

$ghUrl = "https://github.com/$GitHubRepo/releases/download/v$ver/$assetName"
$nasUrl = "$NasBaseUrl/$assetName"

$manifest = [ordered]@{
    version        = $ver
    notes          = $Notes
    apkUrl         = $ghUrl
    fallbackApkUrl = $nasUrl
    sha256         = $hash
    size           = $size
    publishedAt    = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
} | ConvertTo-Json -Depth 4

$manifestPath = Join-Path $root 'update\latest.json'
Set-Content -Path $manifestPath -Value $manifest -Encoding UTF8
Write-Output "==> 写入 $manifestPath"

# 同步 pubspec / update_config 的版本号（靠 version_sync_test 兜底校验）
$pubspec = Join-Path $root 'pubspec.yaml'
$cfg = Join-Path $root 'lib\features\update\update_config.dart'
foreach ($f in @($pubspec, $cfg)) {
    $text = [System.IO.File]::ReadAllText($f, [System.Text.Encoding]::UTF8)
    if ($f -eq $pubspec) {
        $text = [regex]::Replace($text, '(?m)^version:\s*[0-9A-Za-z.\-+]+', "version: $ver+1")
    }
    else {
        $text = [regex]::Replace($text, "defaultValue: '[0-9A-Za-z.\-]+',", "defaultValue: '$ver',")
    }
    [System.IO.File]::WriteAllText($f, $text, (New-Object System.Text.UTF8Encoding($false)))
}
Write-Output '==> 已同步 pubspec.yaml 与 update_config.dart 的版本号'

if ($NasDir -and (Test-Path $NasDir)) {
    Copy-Item $distApk (Join-Path $NasDir $assetName) -Force
    Copy-Item $manifestPath (Join-Path $NasDir 'latest.json') -Force
    Write-Output "==> 已拷贝到 NASHub：$NasDir"
}
elseif ($NasDir) {
    Write-Warning "NASHub 目录不存在，跳过拷贝：$NasDir"
}

Write-Output ''
Write-Output '下一步（GitHub 通道）：'
Write-Output "  gh release create v$ver `"$distApk`" --title `"v$ver`" --notes `"$Notes`""
Write-Output '  git add update/latest.json pubspec.yaml lib/features/update/update_config.dart'
Write-Output "  git commit -m `"chore(release): v$ver`" && git push"
