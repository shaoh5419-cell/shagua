#!/usr/bin/env python3
"""生成 DDZHelper 应用图标（纯 Python，无外部依赖）"""
import struct, zlib, math, os

def chunk(name, data):
    """生成 PNG chunk"""
    body = name + data
    return struct.pack('>I', len(data)) + body + struct.pack('>I', zlib.crc32(body) & 0xffffffff)

def make_icon(size):
    """生成深空主题 + 绿色电源环图标（配合主界面设计）"""
    w = h = size
    cx, cy = w / 2.0, h / 2.0
    R = size / 2.0

    rows = []
    for y in range(h):
        row = bytearray([0])  # Filter type: None
        for x in range(w):
            dx = (x - cx) / R
            dy = (y - cy) / R
            dist = math.sqrt(dx*dx + dy*dy)

            # 背景：深空蓝渐变（径向，中心亮）
            fade = max(0.0, 1.0 - dist * 0.85)
            bg_r = int(8 + 15 * fade)
            bg_g = int(10 + 18 * fade)
            bg_b = int(22 + 38 * fade)

            fr, fg, fb = bg_r, bg_g, bg_b

            # 绿色光环（模仿主界面电源按钮）
            ring_radius = 0.60    # 环中心半径
            ring_width = 0.12      # 环宽度
            ring_dist = abs(dist - ring_radius)

            if ring_dist < ring_width:
                # 环内，计算亮度分布（中心最亮）
                t = 1.0 - ring_dist / ring_width
                t = t * t  # 平方让亮度过渡更自然

                green_r = int(18 + 10 * t)
                green_g = int(200 + 55 * t)
                green_b = int(75 + 20 * t)

                # 与背景混合
                blend = t * 0.9
                fr = int(green_r * blend + bg_r * (1 - blend))
                fg = int(green_g * blend + bg_g * (1 - blend))
                fb = int(green_b * blend + bg_b * (1 - blend))

            # 内圆轻微提亮（模拟立体感）
            if dist < ring_radius - ring_width * 0.6:
                lift = max(0.0, 1.0 - dist / (ring_radius - ring_width))
                lift *= 0.15
                fr = int(min(255, fr + 12 * lift))
                fg = int(min(255, fg + 25 * lift))
                fb = int(min(255, fb + 15 * lift))

            # 外圈光晕（轻微绿光外溢）
            if ring_radius + ring_width < dist < ring_radius + ring_width * 2.2:
                glow = 1.0 - (dist - ring_radius - ring_width) / (ring_width * 1.2)
                glow = max(0.0, glow) ** 2 * 0.5
                fr = int(min(255, fr + 15 * glow))
                fg = int(min(255, fg + 80 * glow))
                fb = int(min(255, fb + 30 * glow))

            row.extend([
                max(0, min(255, fr)),
                max(0, min(255, fg)),
                max(0, min(255, fb))
            ])
        rows.append(bytes(row))

    raw = b''.join(rows)

    sig = b'\x89PNG\r\n\x1a\n'
    ihdr = chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0))
    idat = chunk(b'IDAT', zlib.compress(raw, 6))
    iend = chunk(b'IEND', b'')
    return sig + ihdr + idat + iend

# 在脚本所在目录的 Resources/ 下生成
script_dir = os.path.dirname(os.path.abspath(__file__))
res_dir = os.path.join(script_dir, 'Resources')
os.makedirs(res_dir, exist_ok=True)

# 生成多个尺寸（包括多任务切换器用的小图标）
sizes = [
    ('AppIcon40x40@2x.png', 80),   # 多任务切换器
    ('AppIcon40x40@3x.png', 120),  # 多任务切换器
    ('AppIcon60x60@2x.png', 120),  # 主屏幕
    ('AppIcon60x60@3x.png', 180),  # 主屏幕
]

for name, size in sizes:
    path = os.path.join(res_dir, name)
    with open(path, 'wb') as f:
        f.write(make_icon(size))
    print(f"Generated {name} ({size}x{size})")

print("App icons generated successfully")
