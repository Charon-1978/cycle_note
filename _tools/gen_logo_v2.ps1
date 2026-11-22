# _tools/gen_logo_v2.ps1
#
# 以「旧版月记图标」为模板的**重新设计**（不是修图）：全部矢量绘制，1024 母版起画。
# 保留原图的设计语言：浅粉→淡紫渐变底、中心柔光、女性侧脸、双弧线、右下小月牙。
#
# 两个方案：
#   A 侧脸版（贴近模板）：
#   B 极简版（只留月牙 + 双弧线 + 柔光，去掉人脸，小尺寸更稳）
#
# 只输出到 docs/logo/v2-*.png，不覆盖 res/（选定后再接入）。

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

public static class LogoV2
{
    static GraphicsPath RoundRect(RectangleF r, float radius)
    {
        var p = new GraphicsPath();
        float d = radius * 2;
        p.AddArc(r.X, r.Y, d, d, 180, 90);
        p.AddArc(r.Right - d, r.Y, d, d, 270, 90);
        p.AddArc(r.Right - d, r.Bottom - d, d, d, 0, 90);
        p.AddArc(r.X, r.Bottom - d, d, d, 90, 90);
        p.CloseFigure();
        return p;
    }

    static GraphicsPath Circle(PointF c, float r)
    {
        var p = new GraphicsPath();
        p.AddEllipse(c.X - r, c.Y - r, r * 2, r * 2);
        return p;
    }

    static GraphicsPath Crescent(PointF c, float r, PointF bite, float biteR)
    {
        var a = Circle(c, r);
        var b = Circle(bite, biteR);
        var res = new GraphicsPath();
        res.AddPath(a, false);
        var region = new Region(a);
        region.Exclude(b);
        res = new GraphicsPath();
        res.AddRectangles(new[] { RectangleF.FromLTRB(0, 0, 4096, 4096) });
        a.Dispose(); b.Dispose();
        // 调用方用 Region 填充，返回空路径仅作占位
        return res;
    }

    // 把 0..1 坐标映射到画布
    static PointF P(float x, float y, float s) { return new PointF(x * s, y * s); }

    static void Sparkle(Graphics g, PointF c, float r)
    {
        using (var path = new GraphicsPath())
        using (var b = new PathGradientBrush(Circle(c, r)))
        {
            b.CenterColor = Color.FromArgb(220, 255, 255, 255);
            b.SurroundColors = new[] { Color.FromArgb(0, 255, 255, 255) };
            g.FillEllipse(b, c.X - r, c.Y - r, r * 2, r * 2);
        }
    }

    static void Halo(Graphics g, PointF c, float r, int alpha)
    {
        using (var b = new PathGradientBrush(Circle(c, r)))
        {
            b.CenterColor = Color.FromArgb(alpha, 255, 255, 255);
            b.SurroundColors = new[] { Color.FromArgb(0, 255, 255, 255) };
            b.FocusScales = new PointF(0.25f, 0.25f);
            g.FillEllipse(b, c.X - r, c.Y - r, r * 2, r * 2);
        }
    }

    static void DrawFace(Graphics g, float s)
    {
        // 胸像剪影（cameo）：头 + 颈 + 肩，轮廓右侧是面朝右的侧脸。
        // 只画"人形"不画五官细节 —— 小尺寸下也能读成"一个女性的侧影"。
        var path = new GraphicsPath();
        path.StartFigure();
        path.AddBezier(P(0.460f, 0.285f, s), P(0.500f, 0.285f, s), P(0.525f, 0.315f, s), P(0.528f, 0.360f, s));
        path.AddBezier(P(0.528f, 0.360f, s), P(0.532f, 0.395f, s), P(0.545f, 0.420f, s), P(0.552f, 0.445f, s));
        path.AddBezier(P(0.552f, 0.445f, s), P(0.560f, 0.470f, s), P(0.588f, 0.482f, s), P(0.590f, 0.500f, s));
        path.AddBezier(P(0.590f, 0.500f, s), P(0.591f, 0.512f, s), P(0.570f, 0.518f, s), P(0.560f, 0.525f, s));
        path.AddBezier(P(0.560f, 0.525f, s), P(0.572f, 0.532f, s), P(0.576f, 0.541f, s), P(0.564f, 0.548f, s));
        path.AddBezier(P(0.564f, 0.548f, s), P(0.576f, 0.556f, s), P(0.576f, 0.566f, s), P(0.560f, 0.572f, s));
        path.AddBezier(P(0.560f, 0.572f, s), P(0.548f, 0.584f, s), P(0.534f, 0.600f, s), P(0.527f, 0.618f, s));
        path.AddBezier(P(0.527f, 0.618f, s), P(0.522f, 0.640f, s), P(0.520f, 0.660f, s), P(0.522f, 0.680f, s));
        path.AddBezier(P(0.522f, 0.680f, s), P(0.560f, 0.700f, s), P(0.640f, 0.706f, s), P(0.700f, 0.762f, s));
        path.AddLine(P(0.700f, 0.762f, s), P(0.240f, 0.762f, s));
        path.AddBezier(P(0.240f, 0.762f, s), P(0.300f, 0.700f, s), P(0.330f, 0.660f, s), P(0.336f, 0.620f, s));
        path.AddBezier(P(0.336f, 0.620f, s), P(0.342f, 0.560f, s), P(0.330f, 0.480f, s), P(0.340f, 0.420f, s));
        path.AddBezier(P(0.340f, 0.420f, s), P(0.352f, 0.340f, s), P(0.400f, 0.285f, s), P(0.460f, 0.285f, s));
        path.CloseFigure();
        var brush = new LinearGradientBrush(
            P(0.30f, 0.30f, s), P(0.62f, 0.84f, s),
            Color.FromArgb(250, 253, 228, 238),
            Color.FromArgb(238, 198, 164, 233));
        brush.SetSigmaBellShape(0.55f);
        g.FillPath(brush, path);
        brush.Dispose();
        path.Dispose();
    }

    // 胸像底部渐隐：让剪影"融进"背景，而不是被一条直线切断（模板就是这么处理的）
    static void FadeBottom(Bitmap bmp, float startFrac, float endFrac)
    {
        var rect = new Rectangle(0, 0, bmp.Width, bmp.Height);
        var data = bmp.LockBits(rect, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
        int stride = data.Stride;
        var buf = new byte[stride * bmp.Height];
        System.Runtime.InteropServices.Marshal.Copy(data.Scan0, buf, 0, buf.Length);
        float s = bmp.Height;
        for (int y = 0; y < bmp.Height; y++)
        {
            float t = y / s;
            float a = t <= startFrac ? 1f : 1f - (t - startFrac) / (endFrac - startFrac);
            if (a <= 0f) a = 0f; if (a >= 1f) continue;
            for (int x = 0; x < bmp.Width; x++)
            {
                int i = y * stride + x * 4 + 3;
                buf[i] = (byte)(buf[i] * a);
            }
        }
        System.Runtime.InteropServices.Marshal.Copy(buf, 0, data.Scan0, buf.Length);
        bmp.UnlockBits(data);
    }

    static void DrawFaceLayer(Graphics g, float s)
    {
        int n = (int)s;
        using (var layer = new Bitmap(n, n, PixelFormat.Format32bppArgb))
        using (var lg = Graphics.FromImage(layer))
        {
            lg.SmoothingMode = SmoothingMode.AntiAlias;
            lg.PixelOffsetMode = PixelOffsetMode.HighQuality;
            DrawFace(lg, s);
            FadeBottom(layer, 0.64f, 0.80f);
            g.DrawImage(layer, 0, 0);
        }
    }
    static void DrawCurves(Graphics g, float s)
    {
        var c1 = Color.FromArgb(255, 196, 92, 140);
        var c2 = Color.FromArgb(255, 126, 108, 226);

        using (var b1 = new LinearGradientBrush(P(0.10f, 0.80f, s), P(0.90f, 0.66f, s), c1, c2))
        using (var pen = new Pen(b1, 0.014f * s) { StartCap = LineCap.Round, EndCap = LineCap.Round })
        {
            var p = new GraphicsPath();
            p.AddBezier(P(0.115f, 0.840f, s), P(0.330f, 0.930f, s), P(0.620f, 0.918f, s), P(0.885f, 0.770f, s));
            g.DrawPath(pen, p);
            p.Dispose();
        }
        using (var b2 = new LinearGradientBrush(P(0.10f, 0.86f, s), P(0.92f, 0.72f, s), c1, c2))
        using (var pen = new Pen(b2, 0.009f * s) { StartCap = LineCap.Round, EndCap = LineCap.Round })
        {
            var p = new GraphicsPath();
            p.AddBezier(P(0.105f, 0.888f, s), P(0.340f, 0.978f, s), P(0.640f, 0.962f, s), P(0.905f, 0.822f, s));
            g.DrawPath(pen, p);
            p.Dispose();
        }
    }

    static void DrawCrescentMoon(Graphics g, float s)
    {
        var outer = Circle(P(0.760f, 0.620f, s), 0.080f * s);
        var bite = Circle(P(0.795f, 0.594f, s), 0.074f * s);
        var region = new Region(outer);
        region.Exclude(bite);
        using (var b = new SolidBrush(Color.FromArgb(235, 255, 255, 255)))
        {
            g.FillRegion(b, region);
        }
        region.Dispose(); outer.Dispose(); bite.Dispose();
    }

    public static void Render(string outPath, int size, bool withFace)
    {
        using (var bmp = new Bitmap(size, size, PixelFormat.Format32bppArgb))
        using (var g = Graphics.FromImage(bmp))
        {
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.CompositingQuality = CompositingQuality.HighQuality;
            float s = size;

            // 1) 底：浅粉 → 淡紫（对角）
            using (var bg = new LinearGradientBrush(
                new PointF(0, 0), new PointF(s, s),
                Color.FromArgb(255, 252, 228, 236),
                Color.FromArgb(255, 228, 224, 246)))
            {
                g.FillRectangle(bg, 0, 0, s, s);
            }

            // 2) 中心柔光
            Halo(g, P(0.470f, 0.455f, s), 0.430f * s, 235);
            Halo(g, P(0.470f, 0.455f, s), 0.330f * s, 200);

            // 3) 侧脸背后的发丝（月牙形，粉→紫）；极简版不需要
            if (withFace) {
            var hairOuter = Circle(P(0.352f, 0.470f, s), 0.225f * s);
            var hairBite = Circle(P(0.470f, 0.420f, s), 0.205f * s);
            var hair = new Region(hairOuter);
            hair.Exclude(hairBite);
            using (var b = new LinearGradientBrush(
                P(0.20f, 0.30f, s), P(0.55f, 0.75f, s),
                Color.FromArgb(240, 250, 186, 198),
                Color.FromArgb(240, 214, 170, 226)))
            {
                g.FillRegion(b, hair);
            }
            hair.Dispose(); hairOuter.Dispose(); hairBite.Dispose();
            }

            // 4) 侧脸
            if (withFace) DrawFaceLayer(g, s);

            // 5) 双弧线
            DrawCurves(g, s);

            // 6) 右下小月牙（只在侧脸版；极简版用主月牙）
            if (withFace)
            {
                DrawCrescentMoon(g, s);
                Sparkle(g, P(0.790f, 0.290f, s), 0.018f * s);
                Sparkle(g, P(0.210f, 0.245f, s), 0.012f * s);
                Sparkle(g, P(0.830f, 0.505f, s), 0.009f * s);
            }
            else
            {
                // 极简版：大月牙居中 + 双弧线
                var m1 = Circle(P(0.455f, 0.470f, s), 0.205f * s);
                var m2 = Circle(P(0.588f, 0.412f, s), 0.196f * s);
                var region = new Region(m1);
                region.Exclude(m2);
                using (var b = new LinearGradientBrush(
                    P(0.25f, 0.25f, s), P(0.60f, 0.75f, s),
                    Color.FromArgb(252, 250, 160, 180),
                    Color.FromArgb(252, 176, 140, 236)))
                {
                    g.FillRegion(b, region);
                }
                region.Dispose(); m1.Dispose(); m2.Dispose();
                Sparkle(g, P(0.760f, 0.300f, s), 0.016f * s);
                using (var dot = new SolidBrush(Color.FromArgb(255, 228, 88, 111)))
                    g.FillEllipse(dot, P(0.648f, 0.398f, s).X, P(0.648f, 0.398f, s).Y, 0.062f * s, 0.062f * s);
            }

            bmp.Save(outPath, ImageFormat.Png);
        }
    }
}
'@

$out = Join-Path (Split-Path -Parent $PSScriptRoot) 'docs\logo'
[LogoV2]::Render((Join-Path $out 'v2-a-face-512.png'), 512, $true)
[LogoV2]::Render((Join-Path $out 'v2-a-master-1024.png'), 1024, $true)
[LogoV2]::Render((Join-Path $out 'v2-b-master-1024.png'), 1024, $false)
foreach ($sz in 48, 72, 96, 192) {
    [LogoV2]::Render((Join-Path $out ('v2-a-' + $sz + '.png')), $sz, $true)
    [LogoV2]::Render((Join-Path $out ('v2-b-' + $sz + '.png')), $sz, $false)
}
[LogoV2]::Render((Join-Path $out 'v2-b-minimal-512.png'), 512, $false)
Write-Output 'rendered'
