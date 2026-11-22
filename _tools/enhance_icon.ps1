# _tools/enhance_icon.ps1
#
# 把从旧 APK 提取的 192px 图标做一次"可控的优化"，再落回工程：
#   1) Lanczos3 放大 4 倍成 768 母版（比 GDI+ 的双三次锐利，且不做 over-sharpen）；
#   2) 轻量 unsharp mask（半径 1.0、强度 0.5）找回被放大糊掉的边缘；
#   3) 传统图标：按目标尺寸从母版重采样，并把四角做成**真正的透明圆角**（原图四角是不透明白粉色，桌面上会显示成方块）；
#   4) 小尺寸（48/72）额外放大 6% 并轻微提饱和：原图细线在小图标上会糊成一片；
#   5) 自适应前景：母版缩到 78% + 边缘羽化（沿用 extract_icon 的做法）；
#   6) 1024 商店图：母版 Lanczos 到 1024 再轻锐化。
#
# 只做"还原度优先"的处理：不重绘、不改配色、不加元素。
# 兼容 Windows PowerShell 5.1（UTF-8 BOM）。

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class ImgOps
{
    // ---------- 读写 ----------
    public static byte[] Load(string path, out int w, out int h)
    {
        using (var src = new Bitmap(path))
        using (var bmp = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb))
        {
            using (var g = Graphics.FromImage(bmp)) g.DrawImage(src, 0, 0, src.Width, src.Height);
            w = bmp.Width; h = bmp.Height;
            var rect = new Rectangle(0, 0, w, h);
            var data = bmp.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            var buf = new byte[w * h * 4];
            for (int y = 0; y < h; y++)
                Marshal.Copy(IntPtr.Add(data.Scan0, y * data.Stride), buf, y * w * 4, w * 4);
            bmp.UnlockBits(data);
            return buf;
        }
    }

    public static void Save(byte[] px, int w, int h, string path)
    {
        using (var bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb))
        {
            var rect = new Rectangle(0, 0, w, h);
            var data = bmp.LockBits(rect, ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
            for (int y = 0; y < h; y++)
                Marshal.Copy(px, y * w * 4, IntPtr.Add(data.Scan0, y * data.Stride), w * 4);
            bmp.UnlockBits(data);
            bmp.Save(path, ImageFormat.Png);
        }
    }

    // ---------- Lanczos3 重采样（预乘 alpha，避免边缘发黑） ----------
    static double Sinc(double x)
    {
        if (x == 0) return 1.0;
        double ax = Math.Abs(x);
        if (ax >= 3.0) return 0.0;
        double px = Math.PI * x;
        return Math.Sin(px) / px * Math.Sin(px / 3.0) / (px / 3.0);
    }

    public static byte[] Resize(byte[] src, int sw, int sh, int dw, int dh)
    {
        // 预乘
        var pre = new double[sw * sh * 4];
        for (int i = 0; i < sw * sh; i++)
        {
            double a = src[i * 4 + 3] / 255.0;
            pre[i * 4 + 0] = src[i * 4 + 0] * a;
            pre[i * 4 + 1] = src[i * 4 + 1] * a;
            pre[i * 4 + 2] = src[i * 4 + 2] * a;
            pre[i * 4 + 3] = src[i * 4 + 3];
        }

        var tmp = new double[dw * sh * 4];
        double sx = (double)sw / dw;
        for (int y = 0; y < sh; y++)
            for (int x = 0; x < dw; x++)
            {
                double cx = (x + 0.5) * sx - 0.5;
                int x0 = (int)Math.Floor(cx) - 2;
                double wsum = 0;
                var acc = new double[4];
                for (int t = 0; t < 6; t++)
                {
                    int xi = x0 + t;
                    if (xi < 0) xi = 0; if (xi >= sw) xi = sw - 1;
                    double wgt = Sinc(cx - xi);
                    wsum += wgt;
                    for (int c = 0; c < 4; c++) acc[c] += pre[(y * sw + xi) * 4 + c] * wgt;
                }
                for (int c = 0; c < 4; c++) tmp[(y * dw + x) * 4 + c] = acc[c] / wsum;
            }

        var outp = new double[dw * dh * 4];
        double sy = (double)sh / dh;
        for (int y = 0; y < dh; y++)
        {
            double cy = (y + 0.5) * sy - 0.5;
            int y0 = (int)Math.Floor(cy) - 2;
            for (int x = 0; x < dw; x++)
            {
                double wsum = 0;
                var acc = new double[4];
                for (int t = 0; t < 6; t++)
                {
                    int yi = y0 + t;
                    if (yi < 0) yi = 0; if (yi >= sh) yi = sh - 1;
                    double wgt = Sinc(cy - yi);
                    wsum += wgt;
                    for (int c = 0; c < 4; c++) acc[c] += tmp[(yi * dw + x) * 4 + c] * wgt;
                }
                for (int c = 0; c < 4; c++) outp[(y * dw + x) * 4 + c] = acc[c] / wsum;
            }
        }

        // 反预乘
        var res = new byte[dw * dh * 4];
        for (int i = 0; i < dw * dh; i++)
        {
            double a = outp[i * 4 + 3];
            double af = a / 255.0;
            for (int c = 0; c < 3; c++)
            {
                double v = af <= 0.0001 ? 0 : outp[i * 4 + c] / af;
                res[i * 4 + c] = (byte)Math.Max(0, Math.Min(255, v));
            }
            res[i * 4 + 3] = (byte)Math.Max(0, Math.Min(255, a));
        }
        return res;
    }

    // 大比例缩小要逐级减半，否则 3-lobe 核在 768→48 时会欠采样（细线断成点）
    public static byte[] ResizeAuto(byte[] src, int sw, int sh, int dw, int dh)
    {
        while (sw / 2 >= dw && sh / 2 >= dh)
        {
            src = Resize(src, sw, sh, sw / 2, sh / 2);
            sw /= 2; sh /= 2;
        }
        return Resize(src, sw, sh, dw, dh);
    }
    // ---------- 轻度锐化（unsharp mask，只作用于 RGB） ----------
    public static void Unsharp(byte[] px, int w, int h, double amount, double radius)
    {
        var copy = (byte[])px.Clone();
        int r = Math.Max(1, (int)Math.Round(radius));
        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
            {
                int i = (y * w + x) * 4;
                if (px[i + 3] == 0) continue;
                for (int c = 0; c < 3; c++)
                {
                    double sum = 0; int n = 0;
                    for (int dy = -r; dy <= r; dy++)
                        for (int dx = -r; dx <= r; dx++)
                        {
                            int xx = x + dx, yy = y + dy;
                            if (xx < 0 || yy < 0 || xx >= w || yy >= h) continue;
                            sum += copy[(yy * w + xx) * 4 + c]; n++;
                        }
                    double blur = sum / n;
                    double v = copy[i + c] + amount * (copy[i + c] - blur);
                    px[i + c] = (byte)Math.Max(0, Math.Min(255, v));
                }
            }
    }

    // ---------- 饱和度 / 对比度 ----------
    public static void Adjust(byte[] px, int w, int h, double sat, double contrast)
    {
        for (int i = 0; i < w * h; i++)
        {
            int o = i * 4;
            if (px[o + 3] == 0) continue;
            double r = px[o], g = px[o + 1], b = px[o + 2];
            double lum = 0.299 * r + 0.587 * g + 0.114 * b;
            r = lum + (r - lum) * sat;
            g = lum + (g - lum) * sat;
            b = lum + (b - lum) * sat;
            r = (r - 128) * contrast + 128;
            g = (g - 128) * contrast + 128;
            b = (b - 128) * contrast + 128;
            px[o] = (byte)Math.Max(0, Math.Min(255, r));
            px[o + 1] = (byte)Math.Max(0, Math.Min(255, g));
            px[o + 2] = (byte)Math.Max(0, Math.Min(255, b));
        }
    }

    // ---------- 圆角遮罩（radiusFrac 相对短边） ----------
    public static void RoundCorners(byte[] px, int w, int h, double radiusFrac)
    {
        double r = Math.Min(w, h) * radiusFrac;
        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
            {
                double dx = 0, dy = 0;
                if (x < r) dx = r - x - 0.5; else if (x > w - r) dx = x - (w - r) + 0.5;
                if (y < r) dy = r - y - 0.5; else if (y > h - r) dy = y - (h - r) + 0.5;
                double d = Math.Sqrt(dx * dx + dy * dy);
                double a = d <= r - 1 ? 1.0 : (d >= r ? 0.0 : (r - d));
                int i = (y * w + x) * 4;
                px[i + 3] = (byte)(px[i + 3] * a);
            }
    }

    // ---------- 中心放大（zoom>1 裁掉边缘，让小图标主体更大） ----------
    public static byte[] Zoom(byte[] src, int w, int h, double zoom)
    {
        double cw = w / zoom, ch = h / zoom;
        double x0 = (w - cw) / 2.0, y0 = (h - ch) / 2.0;
        var outp = new byte[w * h * 4];
        for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
            {
                double sx = x0 + x * cw / w;
                double sy = y0 + y * ch / h;
                int ix = (int)Math.Min(w - 1, Math.Max(0, Math.Round(sx)));
                int iy = (int)Math.Min(h - 1, Math.Max(0, Math.Round(sy)));
                Buffer.BlockCopy(src, (iy * w + ix) * 4, outp, (y * w + x) * 4, 4);
            }
        return outp;
    }

    // ---------- 羽化（自适应前景用） ----------
    public static void Feather(byte[] px, int size, double innerR, double outerR)
    {
        double c = size / 2.0, rIn = size * innerR, rOut = size * outerR;
        for (int y = 0; y < size; y++)
            for (int x = 0; x < size; x++)
            {
                double dx = x + 0.5 - c, dy = y + 0.5 - c;
                double d = Math.Sqrt(dx * dx + dy * dy);
                double a = d <= rIn ? 1.0 : (d >= rOut ? 0.0 : 1.0 - ((d - rIn) / (rOut - rIn)) * ((d - rIn) / (rOut - rIn)) * (3 - 2 * ((d - rIn) / (rOut - rIn))));
                int i = (y * size + x) * 4;
                px[i + 3] = (byte)(px[i + 3] * Math.Max(0, Math.Min(1, a)));
            }
    }
}
'@

# 仓库根目录：脚本从 _tools/ 里跑，往上一层就是根（不再写死本机路径）
$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path $root 'docs\logo\source\ic_launcher-xxxhdpi.png'
$res = Join-Path $root 'android\app\src\main\res'
$cmp = Join-Path $root 'docs\logo'

$w = 0; $h = 0
$base = [ImgOps]::Load($src, [ref]$w, [ref]$h)
Write-Output "source ${w}x${h}"

# 1) 4x Lanczos 母版 + 轻锐化
#    两份母版：
#      masterOpaque —— 传统图标用（保留完整方底，最后再切圆角）
#      masterMasked —— 自适应前景用（先在源图上按半径 0.435→0.50 淡出，
#                      把原图自带的浅色方底吃掉，避免圆形裁切里出现方块边）
$masterOpaque = [ImgOps]::Resize($base, $w, $h, $w * 4, $h * 4)
[ImgOps]::Unsharp($masterOpaque, $w * 4, $h * 4, 0.45, 1.0)

$maskedBase = [byte[]]$base.Clone()
[ImgOps]::Feather($maskedBase, $w, 0.435, 0.50)
$masterMasked = [ImgOps]::Resize($maskedBase, $w, $h, $w * 4, $h * 4)
Write-Output "master $($w * 4)x$($h * 4)"

# 2) 传统图标（透明圆角；48/72 额外放大 6% + 提饱和）
$legacy = @{ 'mdpi' = 48; 'hdpi' = 72; 'xhdpi' = 96; 'xxhdpi' = 144; 'xxxhdpi' = 192 }
foreach ($k in $legacy.Keys) {
    $size = [int]$legacy[$k]
    $img = [ImgOps]::ResizeAuto($masterOpaque, $w * 4, $h * 4, $size, $size)
    if ($size -le 72) {
        $img = [ImgOps]::Zoom($img, $size, $size, 1.06)
        [ImgOps]::Adjust($img, $size, $size, 1.08, 1.03)
    }
    [ImgOps]::RoundCorners($img, $size, $size, 0.22)
    $out = Join-Path $res ('mipmap-' + $k + '\ic_launcher.png')
    [ImgOps]::Save($img, $size, $size, $out)
}

# 3) 自适应前景：**满幅铺满**（不裁圆、不加蒙版）
#    原图是一张自带浅粉渐变的圆角方图；如果缩到 78% 再羽化，
#    图内浅粉与自适应底色之间会出现一圈"方片"过渡（实测很显眼）。
#    所以这里直接让原图铺满画布：启动器按自己的形状（圆/方圆/水滴）裁切，
#    用户看到的仍是原图中央的光晕与侧脸，不会出现任何方边。
$fgSize = @{ 'mdpi' = 108; 'hdpi' = 162; 'xhdpi' = 216; 'xxhdpi' = 324; 'xxxhdpi' = 432 }
foreach ($k in $fgSize.Keys) {
    $size = [int]$fgSize[$k]
    # 1.03 过扫，避免某些启动器裁切后露出 1px 透明边
    $big = [int]($size * 1.03)
    $img = [ImgOps]::ResizeAuto($masterOpaque, $w * 4, $h * 4, $big, $big)
    $canvas = New-Object byte[] ($size * $size * 4)
    $off = [int](($big - $size) / 2)
    for ($y = 0; $y -lt $size; $y++) {
        [Array]::Copy($img, (($y + $off) * $big + $off) * 4, $canvas, ($y * $size) * 4, $size * 4)
    }
    [ImgOps]::Save($canvas, $size, $size, (Join-Path $res ('mipmap-' + $k + '\ic_launcher_foreground.png')))
}
# 4) 1024 商店图（母版放大 + 轻锐化）
$big = [ImgOps]::ResizeAuto($masterOpaque, $w * 4, $h * 4, 1024, 1024)
[ImgOps]::Unsharp($big, 1024, 1024, 0.25, 1.0)
[ImgOps]::Save($big, 1024, 1024, (Join-Path $root 'assets\branding\icon_1024.png'))

# 5) 对比图：原图 / 优化后（192）、48px 小图并排
$before192 = [ImgOps]::Resize($base, $w, $h, 192, 192)
$after192 = [ImgOps]::ResizeAuto($masterOpaque, $w * 4, $h * 4, 192, 192)
[ImgOps]::RoundCorners($after192, 192, 192, 0.22)
$cmpW = 192 * 2 + 24; $cmpH = 192
$cmpPx = New-Object byte[] ($cmpW * $cmpH * 4)
for ($i = 0; $i -lt $cmpPx.Length; $i += 4) { $cmpPx[$i] = 255; $cmpPx[$i + 1] = 255; $cmpPx[$i + 2] = 255; $cmpPx[$i + 3] = 255 }
for ($y = 0; $y -lt 192; $y++) {
    [Array]::Copy($before192, $y * 192 * 4, $cmpPx, ($y * $cmpW) * 4, 192 * 4)
    [Array]::Copy($after192, $y * 192 * 4, $cmpPx, ($y * $cmpW + 192 + 24) * 4, 192 * 4)
}
[ImgOps]::Save($cmpPx, $cmpW, $cmpH, (Join-Path $cmp 'compare-192.png'))

Write-Output 'done'
