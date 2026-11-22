# _tools/push_update_to_nas.ps1
#
# 把「月记」的更新产物推到 NAS（复用 NASHub 项目验证过的 SSH 通道，
# 参数与原 push-to-nas.ps1 保持一致：同样的主机、端口、私钥、安装目录约定）。
#
# 上传两个文件到远端目录：
#   latest.json
#   yueji-<版本>-arm64.apk
#
# 之后由 NAS 上的静态站点（极空间「Web 服务」/ nginx / NASHub 反向代理）暴露：
#   http://<NAS>:<端口>/nashub/yueji/latest.json
#
# 用法：
#   powershell -ExecutionPolicy Bypass -File _tools\push_update_to_nas.ps1 `
#     -Version 1.1.0 -RemoteDir /tmp/zfsv3/sata1/<ID>/data/web/yueji
#
# 说明：
#   · 默认只推到内网地址；要公网可用还需要 DDNS/FRP + HTTPS（见 docs/在线更新与发布.md）；
#   · Android 9+ 默认禁止明文 HTTP，App 侧已用 network_security_config 只对
#     192.168.31.48 放行（见 android/app/src/main/res/xml/network_security_config.xml）。

param(
    [Parameter(Mandatory = $true)][string]$Version,
    [Parameter(Mandatory = $true)][string]$RemoteDir,
    [string]$NasHost = '192.168.31.48',
    [int]$SshPort = 10000,
    [string]$SshUser = 'root',
    [string]$KeyFile = "$env:USERPROFILE\.ssh\z4s",
    [string]$PublicBaseUrl = 'http://192.168.31.48:18080/nashub/yueji'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$ver = $Version.TrimStart('v', 'V')
$apk = Join-Path $root "dist\yueji-$ver-arm64.apk"

if (-not (Test-Path $apk)) {
    throw "找不到 $apk —— 先跑 _tools\publish_update.ps1 -Version $ver"
}
if (-not (Test-Path $KeyFile)) {
    throw "找不到私钥 $KeyFile（NASHub 的 push-to-nas.ps1 用的是 ~\.ssh\z4s）"
}

$manifest = Join-Path $root 'update\latest.json'
if (-not (Test-Path $manifest)) { throw "找不到 $manifest" }

# 把 manifest 里的 fallbackApkUrl 指向这次实际上传的地址
$json = Get-Content $manifest -Raw -Encoding UTF8 | ConvertFrom-Json
$json.fallbackApkUrl = "$PublicBaseUrl/yueji-$ver-arm64.apk"
$json | ConvertTo-Json -Depth 5 | Set-Content $manifest -Encoding UTF8

$sshOpts = @('-i', $KeyFile, '-P', "$SshPort", '-o', 'StrictHostKeyChecking=no', '-o', 'UserKnownHostsFile=NUL')
$target = "$SshUser@${NasHost}"

Write-Host "[1/3] 建目录 $RemoteDir" -ForegroundColor Cyan
& ssh @sshOpts $target "mkdir -p '$RemoteDir'"
if ($LASTEXITCODE -ne 0) { throw 'SSH 失败：免密没配好？先跑 NASHub 的 install-pubkey.sh' }

$sizeMB = [math]::Round((Get-Item $apk).Length / 1MB, 2)
Write-Host "[2/3] 上传 APK ($sizeMB MB)" -ForegroundColor Cyan
& scp @sshOpts $apk "${target}:$RemoteDir/yueji-$ver-arm64.apk"
if ($LASTEXITCODE -ne 0) { throw 'scp 上传 APK 失败' }

Write-Host '[3/3] 上传 latest.json' -ForegroundColor Cyan
& scp @sshOpts $manifest "${target}:$RemoteDir/latest.json"
if ($LASTEXITCODE -ne 0) { throw 'scp 上传 manifest 失败' }

Write-Host ''
Write-Host '完成。远端内容：' -ForegroundColor Green
& ssh @sshOpts $target "ls -lh '$RemoteDir'"

Write-Host ''
Write-Host '预期访问地址（需 NAS 上把该目录挂成静态站点）：'
Write-Host "  $PublicBaseUrl/latest.json"
Write-Host "  $PublicBaseUrl/yueji-$ver-arm64.apk"
Write-Host ''
Write-Host '自测：'
Write-Host "  curl -s $PublicBaseUrl/latest.json"
Write-Host ''
Write-Host '注意：Android 9+ 默认禁明文 HTTP。App 侧只在 network_security_config 里放行了 192.168.31.48；'
Write-Host '      要在公网用，请加 DDNS/FRP + HTTPS，并把 update_config.dart 的 UPDATE_URL_NAS 换成 https 地址。'
