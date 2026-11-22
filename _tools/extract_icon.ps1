# _tools/extract_icon.ps1
#
# 从旧版「月记」APK 解包出的资源里提取启动图标，落回本工程。
# 源：<旧版 APK 解包目录>\res\mipmap-*\ic_launcher.png（放到 docs\logo\source\ 后即可复现）
#     （旧包 com.example.cycle_note 1.0.0 只有传统 mipmap，没有自适应图标）
#
# 产物：
#   res/mipmap-*/ic_launcher.png            原图（48/72/96/144/192）
#   res/mipmap-*/ic_launcher_foreground.png 圆裁 + 缩到安全区，供 Android 8+ 自适应用
#   assets/branding/icon_1024.png           商店/分享图（源图仅 192，放大会偏软）
#
# 兼容性：Windows PowerShell 5.1 要求脚本带 BOM 才能正确解析中文；
# 本文件以 UTF-8 BOM 保存。

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$srcPath = Join-Path $root 'docs\logo\source\ic_launcher-xxxhdpi.png'
if (-not (Test-Path $srcPath)) { throw "缺少源图: $srcPath" }

$img = [System.Drawing.Image]::FromFile($srcPath)
$w = [int]$img.Width
$h = [int]$img.Height
$bmp = New-Object System.Drawing.Bitmap -ArgumentList $img

# --- 1) 四角平均色 = 自适应背景色 ---
$p1 = $bmp.GetPixel(4, 4)
$p2 = $bmp.GetPixel($w - 5, 4)
$p3 = $bmp.GetPixel(4, $h - 5)
$p4 = $bmp.GetPixel($w - 5, $h - 5)
$bgR = [int](($p1.R + $p2.R + $p3.R + $p4.R) / 4)
$bgG = [int](($p1.G + $p2.G + $p3.G + $p4.G) / 4)
$bgB = [int](($p1.B + $p2.B + $p3.B + $p4.B) / 4)
$bgHex = '#{0:X2}{1:X2}{2:X2}' -f $bgR, $bgG, $bgB
Write-Output "ic_launcher_background = $bgHex"

$res = Join-Path $root 'android\app\src\main\res'

# --- 2) 传统图标：原样复制 ---
$legacy = @{ 'mdpi' = 48; 'hdpi' = 72; 'xhdpi' = 96; 'xxhdpi' = 144; 'xxxhdpi' = 192 }
foreach ($k in $legacy.Keys) {
    $dstDir = Join-Path $res ('mipmap-' + $k)
    if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir | Out-Null }
    $from = Join-Path $root ('docs\logo\source\ic_launcher-' + $k + '.png')
    Copy-Item $from (Join-Path $dstDir 'ic_launcher.png') -Force
}

# --- 3) 自适应前景：缩到安全区 + 边缘羽化（去掉原图的浅色方底硬边） ---
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class IconFeather
{
    /// src 缩到 size*scale 居中，再按半径做平滑 alpha 淡出（innerR/outerR 是相对 size 的半径比例）。
    /// 目的：原图自带浅粉方底，直接塞进自适应图标会出现"圆里套方块"的硬边；
    /// 羽化后边缘融进 background 色，看起来就是一束光晕。
    public static void Run(string src, string dst, int size, double side, double innerR, double outerR)
    {
        using (var img = Image.FromFile(src))
        using (var bmp = new Bitmap(size, size, PixelFormat.Format32bppArgb))
        {
            using (var g = Graphics.FromImage(bmp))
            {
                g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;
                g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
                g.Clear(Color.Transparent);
                double px = size * side;
                double off = (size - px) / 2.0;
                g.DrawImage(img, (float)off, (float)off, (float)px, (float)px);
            }

            var rect = new Rectangle(0, 0, size, size);
            var data = bmp.LockBits(rect, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
            int stride = data.Stride;
            var buf = new byte[stride * size];
            Marshal.Copy(data.Scan0, buf, 0, buf.Length);

            double c = size / 2.0;
            double rIn = size * innerR;
            double rOut = size * outerR;

            for (int y = 0; y < size; y++)
            {
                for (int x = 0; x < size; x++)
                {
                    double dx = x + 0.5 - c;
                    double dy = y + 0.5 - c;
                    double d = Math.Sqrt(dx * dx + dy * dy);
                    double a;
                    if (d <= rIn) a = 1.0;
                    else if (d >= rOut) a = 0.0;
                    else
                    {
                        double t = (d - rIn) / (rOut - rIn);
                        a = 1.0 - (t * t * (3 - 2 * t)); // smoothstep
                    }
                    int i = y * stride + x * 4;
                    buf[i + 3] = (byte)(buf[i + 3] * a);
                }
            }

            Marshal.Copy(buf, 0, data.Scan0, buf.Length);
            bmp.UnlockBits(data);
            bmp.Save(dst, ImageFormat.Png);
        }
    }
}
'@

$fgSize = @{ 'mdpi' = 108; 'hdpi' = 162; 'xhdpi' = 216; 'xxhdpi' = 324; 'xxxhdpi' = 432 }
foreach ($k in $fgSize.Keys) {
    $size = [int]$fgSize[$k]
    $dstDir = Join-Path $res ('mipmap-' + $k)
    $out = Join-Path $dstDir 'ic_launcher_foreground.png'
    # side=0.66 → 主体落在自适应安全区（直径 66%）内；半径 0.27→0.34 羽化
    [IconFeather]::Run($srcPath, $out, $size, 0.78, 0.31, 0.41)
}

# --- 4) 1024 商店图 ---
$big = New-Object System.Drawing.Bitmap -ArgumentList 1024, 1024
$gb = [System.Drawing.Graphics]::FromImage($big)
$gb.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$gb.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$gb.Clear([System.Drawing.Color]::FromArgb(255, $bgR, $bgG, $bgB))
$gb.DrawImage($img, 0, 0, 1024, 1024)
$gb.Dispose()
$big.Save((Join-Path $root 'assets\branding\icon_1024.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$big.Dispose()

$bmp.Dispose()
$img.Dispose()
Write-Output 'done'
