# -*- coding: utf-8 -*-
"""品牌图标生成器（纯标准库）。

为什么不用图像库：本机没有 PIL，也不想为一次性任务引入依赖。
PNG 编码只用 zlib + struct；抗锯齿用距离场（每像素解析计算），
比超采样快一个数量级，边缘质量相当。

图形：玫瑰渐变圆角底 + 白色月牙 + 一颗"周期点"。
"""
import math
import os
import struct
import zlib

TOP = (0xF4, 0xB6, 0xC2)
BOTTOM = (0xC2, 0x54, 0x5E)

LEGACY = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
FOREGROUND = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}


def write_png(path, size, pixels):
    raw = bytearray()
    stride = size * 4
    for y in range(size):
        raw.append(0)  # filter type 0
        raw += pixels[y * stride:(y + 1) * stride]

    def chunk(tag, data):
        body = tag + data
        return (struct.pack(">I", len(data)) + body +
                struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF))

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += chunk(b"IEND", b"")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(png)


def sdf_round_rect(x, y, cx, cy, hw, hh, r):
    dx = abs(x - cx) - (hw - r)
    dy = abs(y - cy) - (hh - r)
    ax = dx if dx > 0 else 0.0
    ay = dy if dy > 0 else 0.0
    return math.hypot(ax, ay) + min(max(dx, dy), 0.0) - r


def render(size, rounded=True, content_scale=1.0, transparent=False):
    px = bytearray(size * size * 4)
    r_corner = 0.22 * size if rounded else 0.0
    half = size / 2.0

    box = size * content_scale
    ox = (size - box) / 2.0
    oy = (size - box) / 2.0

    moon_cx = ox + box * 0.46
    moon_cy = oy + box * 0.52
    mr = box * 0.30
    bite_cx = moon_cx + mr * 0.52
    bite_cy = moon_cy - mr * 0.30
    br = mr * 0.92

    dot_cx = ox + box * 0.74
    dot_cy = oy + box * 0.30
    dr = box * 0.072

    for y in range(size):
        py = y + 0.5
        for x in range(size):
            pxx = x + 0.5
            i = (y * size + x) * 4

            # ---- 底：圆角矩形 + 对角渐变 ----
            if transparent:
                r = g = b = a = 0
            else:
                d = sdf_round_rect(pxx, py, half, half, half, half, r_corner)
                cov = 0.5 - d
                if cov <= 0:
                    continue
                if cov > 1:
                    cov = 1.0
                t = (pxx / size + py / size) / 2.0
                r = int(TOP[0] + (BOTTOM[0] - TOP[0]) * t)
                g = int(TOP[1] + (BOTTOM[1] - TOP[1]) * t)
                b = int(TOP[2] + (BOTTOM[2] - TOP[2]) * t)
                a = int(cov * 255)

            # ---- 月牙：大圆减去偏移圆 ----
            d_out = math.hypot(pxx - moon_cx, py - moon_cy) - mr
            d_bite = math.hypot(pxx - bite_cx, py - bite_cy) - br
            d_moon = max(d_out, -d_bite)
            moon_a = 0.5 - d_moon
            if moon_a > 0:
                if moon_a > 1:
                    moon_a = 1.0
                if transparent:
                    r = g = b = 255
                    a = int(moon_a * 255)
                else:
                    r = int(r + (255 - r) * moon_a)
                    g = int(g + (255 - g) * moon_a)
                    b = int(b + (255 - b) * moon_a)
                    a = int(a + (255 - a) * moon_a)

            # ---- 周期点 ----
            d_dot = math.hypot(pxx - dot_cx, py - dot_cy) - dr
            dot_a = 0.5 - d_dot
            if dot_a > 0:
                if dot_a > 1:
                    dot_a = 1.0
                dot_a *= 0.95
                if transparent:
                    r = g = b = 255
                    a = int(dot_a * 255)
                else:
                    r = int(r + (255 - r) * dot_a)
                    g = int(g + (255 - g) * dot_a)
                    b = int(b + (255 - b) * dot_a)
                    a = int(a + (255 - a) * dot_a)

            px[i] = r
            px[i + 1] = g
            px[i + 2] = b
            px[i + 3] = a
    return px


def main():
    res = "android/app/src/main/res"
    for name, size in LEGACY.items():
        p = os.path.join(res, "mipmap-" + name, "ic_launcher.png")
        write_png(p, size, render(size, rounded=True, content_scale=1.0))
        print("legacy", size, "->", p)

    for name, size in FOREGROUND.items():
        p = os.path.join(res, "mipmap-" + name, "ic_launcher_foreground.png")
        write_png(p, size, render(size, rounded=False, content_scale=0.66,
                                  transparent=True))
        print("fg", size, "->", p)

    p = os.path.join("assets", "branding", "icon_1024.png")
    write_png(p, 1024, render(1024, rounded=True, content_scale=1.0))
    print("branding ->", p)


if __name__ == "__main__":
    main()
