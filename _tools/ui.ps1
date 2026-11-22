# _tools/ui.ps1 —— 模拟器 UI 操作小工具（截图 / 找控件 / 点击 / 输入）
#
# 为什么用 uiautomator dump 而不是按截图比例估坐标：
# 首页的卡片位置会随数据变化，估出来的坐标会差 30px 以上，点错就点到别的控件。
#
# 用法：
#   . <repo>\_tools\ui.ps1
#   Shot -Name 02-me
#   TapText -Text '我的'
#   TypeText -Text '162'

$ErrorActionPreference = 'Continue'
$script:Adb = if ($env:ANDROID_HOME) { Join-Path $env:ANDROID_HOME 'platform-tools\adb.exe' } else { 'adb' }
$script:ShotDir = Join-Path (Split-Path -Parent $PSScriptRoot) '_shots_new'

function Shot {
    param([Parameter(Mandatory)][string]$Name)
    New-Item -ItemType Directory -Force -Path $script:ShotDir | Out-Null
    & $script:Adb shell screencap -p /sdcard/_s.png | Out-Null
    & $script:Adb pull /sdcard/_s.png (Join-Path $script:ShotDir "$Name.png") *> $null
    Write-Output "shot: $Name"
}

function Get-UiXml {
    & $script:Adb shell uiautomator dump /sdcard/_ui.xml | Out-Null
    & $script:Adb shell cat /sdcard/_ui.xml
}

function Find-Node {
    param([Parameter(Mandatory)][string]$Text, [switch]$Exact)
    $xml = Get-UiXml
    $pattern = if ($Exact) { "text=`"$([regex]::Escape($Text))`"" } else { "text=`"[^`"]*$([regex]::Escape($Text))[^`"]*`"" }
    $matches = [regex]::Matches($xml, "<node[^>]*$pattern[^>]*>")
    foreach ($m in $matches) {
        $bounds = [regex]::Match($m.Value, 'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"')
        if (-not $bounds.Success) { continue }
        $x1 = [int]$bounds.Groups[1].Value; $y1 = [int]$bounds.Groups[2].Value
        $x2 = [int]$bounds.Groups[3].Value; $y2 = [int]$bounds.Groups[4].Value
        [pscustomobject]@{
            Text = ([regex]::Match($m.Value, 'text="([^"]*)"')).Groups[1].Value
            X = [int](($x1 + $x2) / 2)
            Y = [int](($y1 + $y2) / 2)
            W = $x2 - $x1
            H = $y2 - $y1
        }
    }
}

function TapText {
    param([Parameter(Mandatory)][string]$Text, [switch]$Exact, [int]$Index = 0)
    $nodes = @(Find-Node -Text $Text -Exact:$Exact)
    if ($nodes.Count -eq 0) {
        # 可能在屏幕外：先滚动一屏再找
        & $script:Adb shell input swipe 540 1800 540 900 300 | Out-Null
        Start-Sleep -Milliseconds 600
        $nodes = @(Find-Node -Text $Text -Exact:$Exact)
    }
    if ($nodes.Count -eq 0) { throw "找不到控件：$Text" }
    $n = $nodes[$Index]
    & $script:Adb shell input tap $n.X $n.Y | Out-Null
    Start-Sleep -Milliseconds 700
    Write-Output "tap: $($n.Text) @ $($n.X),$($n.Y)"
}

function TypeText {
    param([Parameter(Mandatory)][string]$Text)
    & $script:Adb shell input text $Text | Out-Null
    Start-Sleep -Milliseconds 300
}

function SwipeUp {
    param([int]$Times = 1)
    for ($i = 0; $i -lt $Times; $i++) {
        & $script:Adb shell input swipe 540 1700 540 900 250 | Out-Null
        Start-Sleep -Milliseconds 500
    }
}

function Back {
    & $script:Adb shell input keyevent 4 | Out-Null
    Start-Sleep -Milliseconds 700
}

