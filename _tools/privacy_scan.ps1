# _tools/privacy_scan.ps1
#
# GitHub 托管前的隐私 / 密钥自检。**只读**：不修改任何文件，只输出报告。
#
# 用法：
#   powershell -ExecutionPolicy Bypass -File _tools/privacy_scan.ps1
#   powershell -ExecutionPolicy Bypass -File _tools/privacy_scan.ps1 -CheckHistory   # 额外扫 git 历史
#
# 检查项：
#   1) 密钥/令牌模式（GitHub token、OpenAI key、Google API key、AWS key、Slack token、PEM 私钥）；
#   2) 签名材料（*.jks / *.keystore / key.properties / local.properties / *.pem / *.p12）；
#   3) 明文密码字段（storePassword=xxx、keyPassword=xxx）；
#   4) 本机绝对路径（D:\Users\...、C:\Users\...）与设备标识（MAC、UUID、手机号）；
#   5) 会被提交的"体积/垃圾"文件（APK、截图、模拟器日志）；
#   6) 可选：git 历史里是否出现过 *.jks / *.apk / 明文密码。
#
# 退出码：0 = 通过，1 = 有需要人工确认的命中。

param(
    [switch]$CheckHistory
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Push-Location $root

$issues = New-Object System.Collections.Generic.List[string]
$warns = New-Object System.Collections.Generic.List[string]

function Add-Issue($msg) { $script:issues.Add($msg) }
function Add-Warn($msg) { $script:warns.Add($msg) }

# ---------- 1) 排除目录 ----------
$skipDirs = @('build', '.dart_tool', '.git', 'dist', '_shots_new', '_mumu_out', '.gradle', 'node_modules')
function Should-Skip($path) {
    foreach ($d in $skipDirs) { if ($path -match [regex]::Escape("\$d\")) { return $true } }
    return $false
}

# 只扫"会被提交"的文件：被 .gitignore 挡住的（key.properties / 本地日志 / 截图）不算风险，
# 它们进不了仓库；只作为"本机存在"提示列出。
$allFiles = Get-ChildItem -Recurse -File -Include *.dart, *.kt, *.kts, *.yaml, *.yml, *.json, *.md,
    *.ps1, *.py, *.xml, *.properties, *.gradle, *.txt, *.toml, *.sh -ErrorAction SilentlyContinue |
    Where-Object { -not (Should-Skip $_.FullName) }

$ignoredLocal = New-Object System.Collections.Generic.List[string]
$textFiles = @()
foreach ($f in $allFiles) {
    if ($f.Name -eq 'privacy_scan.ps1') { continue }   # 本脚本自己的文档里有示例串
    $rel = $f.FullName.Replace($root + '\', '')
    git check-ignore -q -- $rel 2>$null
    if ($LASTEXITCODE -eq 0) { $ignoredLocal.Add($rel) } else { $textFiles += $f }
}

# ---------- 2) 令牌模式 ----------
$tokenPatterns = [ordered]@{
    'GitHub token'   = 'ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}'
    'OpenAI/Anthropic key' = 'sk-[A-Za-z0-9]{20,}'
    'Google API key' = 'AIza[0-9A-Za-z\-_]{30,}'
    'AWS access key' = 'AKIA[0-9A-Z]{16}'
    'Slack token'    = 'xox[baprs]-[A-Za-z0-9-]{10,}'
    'PEM 私钥'        = '-----BEGIN [A-Z ]*PRIVATE KEY-----'
}

foreach ($name in $tokenPatterns.Keys) {
    $pat = $tokenPatterns[$name]
    $textFiles | Select-String -Pattern $pat -AllMatches -ErrorAction SilentlyContinue |
        ForEach-Object { Add-Issue "[$name] $($_.Path.Replace($root + '\', '')):$($_.LineNumber)" }
}

# ---------- 3) 签名材料是否会被提交 ----------
$sensitiveFiles = Get-ChildItem -Recurse -File -Include *.jks, *.keystore, key.properties,
    local.properties, *.pem, *.p12, *.pfx -ErrorAction SilentlyContinue |
    Where-Object { -not (Should-Skip $_.FullName) }

foreach ($f in $sensitiveFiles) {
    $rel = $f.FullName.Replace($root + '\', '')
    $ignored = git check-ignore -q -- $rel 2>$null
    if ($LASTEXITCODE -eq 0) {
        Add-Warn "[本地存在但已忽略] $rel"
    }
    else {
        Add-Issue "[会被提交！] $rel"
    }
}

# ---------- 4) 明文密码字段 ----------
$textFiles | Select-String -Pattern '(storePassword|keyPassword|api[_-]?key|apikey|secret|token)\s*[:=]\s*[^\s"\$\[][^\s]{5,}' -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -notmatch 'build\.gradle\.kts$|workflows' } |
    ForEach-Object { Add-Issue "[疑似明文凭据] $($_.Path.Replace($root + '\', '')):$($_.LineNumber)" }

# ---------- 5) 本机路径 / 设备标识 ----------
$localPatterns = [ordered]@{
    'Windows 用户目录' = '[A-Za-z]:\\Users\\[A-Za-z0-9._-]+'
    '本机项目路径'     = '[A-Za-z]:\\yueji|[A-Za-z]:\\GradleHome'
    '手机号'           = '(?<!\d)1[3-9]\d{9}(?!\d)'
    '邮箱'             = '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
}
foreach ($name in $localPatterns.Keys) {
    $pat = $localPatterns[$name]
    $textFiles | Select-String -Pattern $pat -AllMatches -ErrorAction SilentlyContinue |
        Where-Object { $_.Line -notmatch 'git@github\.com' } |
        ForEach-Object { Add-Warn "[$name] $($_.Path.Replace($root + '\', '')):$($_.LineNumber)" }
}

# ---------- 6) 会被提交的大文件 / 垃圾 ----------
$tracked = git ls-files
if ($tracked) {
    $tracked | Where-Object { $_ -match '\.apk$|\.jks$|\.aab$|\.zip$|\.sqlite$|\.db$' } |
        ForEach-Object { Add-Issue "[已跟踪的二进制] $_" }
}

$untracked = git status --porcelain --untracked-files=all 2>$null |
    Where-Object { $_ -match '^\?\?' } |
    ForEach-Object { $_.Substring(3).Trim('"') }
$untracked | Where-Object { $_ -match '\.apk$|_shots_new/|_mumu_out/|^_[^/]+$' } |
    ForEach-Object { Add-Warn "[即将被提交的调试产物] $_" }

# ---------- 7) git 历史（可选） ----------
if ($CheckHistory) {
    $hist = git log --all --name-only --pretty=format: 2>$null | Sort-Object -Unique
    $hist | Where-Object { $_ -match '\.jks$|\.keystore$|\.apk$|key\.properties$|local\.properties$|\.p12$|\.pem$' } |
        ForEach-Object { Add-Issue "[历史中出现过] $_" }

    if (Test-Path 'android/key.properties') {
        $vals = Get-Content 'android/key.properties' | ForEach-Object {
            if ($_ -match '^[A-Za-z]+Password=(.+)$') { $matches[1] }
        }
        foreach ($c in (git rev-list --all)) {
            foreach ($v in $vals) {
                $r = git grep -l -F -e $v $c 2>$null
                if ($r) { Add-Issue "[历史中出现明文密码] commit $c" }
            }
        }
    }
}

Pop-Location

# ---------- 报告 ----------
Write-Output ''
Write-Output '===== 月记 · GitHub 托管前隐私自检 ====='
Write-Output "扫描文本文件：$($textFiles.Count) 个"
if ($ignoredLocal.Count -gt 0) {
    Write-Output ""
    Write-Output "本机存在但已被 .gitignore 挡住（不会上传，共 $($ignoredLocal.Count) 个）："
    $ignoredLocal | Select-Object -Unique | ForEach-Object { Write-Output "  ✓ $_" }
}
Write-Output ''
if ($issues.Count -eq 0) {
    Write-Output '阻断项：无'
}
else {
    Write-Output "阻断项（$($issues.Count)）—— 必须处理："
    $issues | ForEach-Object { Write-Output "  ✗ $_" }
}
Write-Output ''
if ($warns.Count -eq 0) {
    Write-Output '提示项：无'
}
else {
    Write-Output "提示项（$($warns.Count)）—— 需人工确认："
    $warns | Select-Object -Unique | ForEach-Object { Write-Output "  · $_" }
}

if ($issues.Count -gt 0) { exit 1 }
exit 0
