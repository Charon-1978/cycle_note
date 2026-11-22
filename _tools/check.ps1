# _tools/check.ps1 —— 一条命令跑完"提交前必过"的检查
#
# 为什么需要它：仓库没有远端 CI，analyze / test / 关键静态校验全靠人记得跑；
# 一旦漏跑，红灯就会被合进来（2026-11-22 就发生过图标生成器把 res 刷脏）。
#
# 用法：
#   pwsh -File <repo>\_tools\check.ps1
#   git 钩子：把下面一行写进 .git/hooks/pre-push（去掉注释）
#     # powershell -NoProfile -File "D:/yueji/_tools/check.ps1" || exit 1
#
# 退出码 0 = 全部通过；非 0 = 有失败项（可以直接阻断提交/推送）。

$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
Push-Location $root

$failed = @()

function Step([string]$name, [scriptblock]$body) {
    Write-Host ""
    Write-Host "== $name ==" -ForegroundColor Cyan
    & $body
    if ($LASTEXITCODE -ne 0) {
        $script:failed += $name
        Write-Host "FAILED: $name" -ForegroundColor Red
    } else {
        Write-Host "ok: $name" -ForegroundColor Green
    }
}

Step 'flutter analyze' { flutter analyze }
Step 'flutter test' { flutter test }

Step '设计令牌：禁止硬编码颜色' {
    # 只允许出现在 theme/ 与 error_handler（白屏兜底的唯一豁免点）
    $hits = Select-String -Path (Get-ChildItem lib -Recurse -Filter *.dart |
            Where-Object { $_.FullName -notmatch 'app\\theme\\' -and $_.Name -ne 'error_handler.dart' } |
            ForEach-Object FullName) -Pattern 'Color\(0x' -ErrorAction SilentlyContinue
    if ($hits) {
        $hits | ForEach-Object { Write-Host "  $($_.Path.Replace($root + '\','')):$($_.LineNumber)" }
        $global:LASTEXITCODE = 1
    } else {
        $global:LASTEXITCODE = 0
    }
}

Step '调试残留：禁止 print(' {
    $hits = Select-String -Path (Get-ChildItem lib -Recurse -Filter *.dart | ForEach-Object FullName) `
        -Pattern '\bprint\(' -ErrorAction SilentlyContinue
    if ($hits) {
        $hits | ForEach-Object { Write-Host "  $($_.Path.Replace($root + '\','')):$($_.LineNumber)" }
        $global:LASTEXITCODE = 1
    } else {
        $global:LASTEXITCODE = 0
    }
}

Step '依赖冻结：pubspec 未被改动' {
    $diff = git diff --name-only -- pubspec.yaml pubspec.lock
    if ($diff) {
        Write-Host "  pubspec 有未提交改动：$diff（若确属需要，请在 PR 说明里写理由）" -ForegroundColor Yellow
    }
    $global:LASTEXITCODE = 0
}

Pop-Location
Write-Host ""
if ($failed.Count -eq 0) {
    Write-Host "全部通过 ✅" -ForegroundColor Green
    exit 0
} else {
    Write-Host "失败项：$($failed -join ' / ')" -ForegroundColor Red
    exit 1
}
