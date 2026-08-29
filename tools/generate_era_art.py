from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "eras"
ENEMY_KINDS = ["normal", "fast", "tank", "ranged", "elite", "berserker", "boss_mamut", "boss_chief", "boss_iron_general"]
UNIT_KINDS = ["militia", "archer", "heavy", "crossbow"]

ERAS = {
    "prehistoric": ((6, 18, 38), (20, 58, 58), (95, 202, 92), (143, 84, 42), "hills"),
    "bronze": ((35, 20, 15), (109, 49, 25), (236, 151, 52), (161, 82, 35), "temple"),
    "iron": ((15, 24, 31), (52, 76, 84), (104, 190, 236), (77, 91, 104), "fortress"),
    "medieval": ((18, 11, 38), (71, 35, 91), (239, 161, 72), (111, 56, 105), "castle"),
    "renaissance": ((39, 15, 47), (113, 39, 58), (255, 196, 82), (153, 73, 77), "arches"),
    "industrial": ((12, 18, 24), (62, 47, 42), (255, 116, 38), (99, 86, 80), "factory"),
    "electrical": ((4, 18, 44), (11, 75, 108), (80, 237, 255), (26, 128, 160), "lightning"),
    "atomic": ((20, 10, 42), (62, 26, 78), (130, 255, 137), (63, 151, 90), "atom"),
    "digital": ((3, 13, 35), (9, 53, 91), (72, 214, 255), (28, 111, 165), "grid"),
    "cybernetic": ((31, 4, 43), (94, 12, 84), (255, 88, 211), (148, 35, 131), "circuit"),
    "space": ((4, 8, 35), (19, 43, 104), (119, 190, 255), (46, 92, 174), "planet"),
    "interstellar": ((18, 4, 49), (75, 14, 120), (225, 115, 255), (128, 47, 168), "nebula"),
    "quantum": ((5, 10, 50), (24, 31, 105), (157, 190, 255), (59, 103, 211), "quantum"),
}


def rgba(color: tuple[int, int, int], alpha: int = 255) -> tuple[int, int, int, int]:
    return color + (alpha,)


def lerp_color(a: tuple[int, int, int], b: tuple[int, int, int], amount: float) -> tuple[int, int, int]:
    return tuple(int(a[i] * (1.0 - amount) + b[i] * amount) for i in range(3))


def gradient(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    image = Image.new("RGB", size)
    pixels = image.load()
    for y in range(size[1]):
        amount = y / max(size[1] - 1, 1)
        color = lerp_color(top, bottom, amount)
        for x in range(size[0]):
            pixels[x, y] = color
    return image.convert("RGBA")


def draw_pine(draw: ImageDraw.ImageDraw, x: int, base_y: int, height: int, color: tuple[int, int, int, int]) -> None:
    trunk = max(4, height // 25)
    draw.rectangle((x - trunk // 2, base_y - height // 8, x + trunk // 2, base_y + 10), fill=(48, 37, 34, 255))
    for index, ratio in enumerate((0.2, 0.43, 0.66, 0.88)):
        tip_y = base_y - int(height * ratio)
        half = int(height * (0.09 + index * 0.035))
        draw.polygon(((x, tip_y), (x - half, base_y - int(height * (ratio - 0.18))), (x + half, base_y - int(height * (ratio - 0.18)))), fill=color)


def draw_cloud(draw: ImageDraw.ImageDraw, x: int, y: int, scale: float, color: tuple[int, int, int, int]) -> None:
    """Soft, layered cloud silhouette for a more illustrated game backdrop."""
    parts = [(-78, 12, 92), (-28, -18, 112), (34, -2, 88), (82, 18, 66)]
    for offset_x, offset_y, radius in parts:
        r = int(radius * scale)
        cx = int(x + offset_x * scale)
        cy = int(y + offset_y * scale)
        draw.ellipse((cx - r, cy - r // 2, cx + r, cy + r // 2), fill=color)
    draw.rounded_rectangle((int(x - 110 * scale), int(y), int(x + 112 * scale), int(y + 46 * scale)), radius=max(4, int(20 * scale)), fill=color)


def draw_sparkle(draw: ImageDraw.ImageDraw, x: int, y: int, size: int, color: tuple[int, int, int, int]) -> None:
    """Small four-point stars used to break up large areas of sky."""
    draw.polygon(((x, y - size), (x + size // 3, y - size // 3), (x + size, y),
                  (x + size // 3, y + size // 3), (x, y + size),
                  (x - size // 3, y + size // 3), (x - size, y),
                  (x - size // 3, y - size // 3)), fill=color)


def draw_mountain_layer(draw: ImageDraw.ImageDraw, points: tuple[tuple[int, int], ...], fill: tuple[int, int, int, int],
                        snow: tuple[int, int, int, int] | None = None) -> None:
    draw.polygon(points, fill=fill)
    if snow is not None:
        # The first two points of each peak are deliberately broad so the snowcap
        # remains readable after Godot scales the 1080x1920 source down.
        for index in range(0, len(points) - 2, 2):
            left = points[index]
            peak = points[index + 1]
            right = points[index + 2]
            cap_width = max(18, int((right[0] - left[0]) * 0.16))
            draw.polygon(((peak[0], peak[1] + 5),
                          (peak[0] - cap_width, peak[1] + cap_width * 2),
                          (peak[0] + cap_width, peak[1] + cap_width * 2)), fill=snow)


def draw_forest_line(draw: ImageDraw.ImageDraw, rng: random.Random, base_y: int,
                     color: tuple[int, int, int, int], count: int, min_height: int, max_height: int) -> None:
    for index in range(count):
        x = int(index * 1080 / max(count - 1, 1)) + rng.randint(-24, 24)
        draw_pine(draw, x, base_y + rng.randint(-12, 14), rng.randint(min_height, max_height), color)


def draw_ground_texture(draw: ImageDraw.ImageDraw, rng: random.Random, ground: tuple[int, int, int], accent: tuple[int, int, int]) -> None:
    for _ in range(180):
        x = rng.randint(0, 1079)
        y = rng.randint(1410, 1900)
        width = rng.randint(4, 24)
        height = rng.randint(2, 9)
        tone = lerp_color(ground, (238, 205, 144), rng.uniform(0.12, 0.42))
        alpha = rng.randint(35, 115)
        draw.ellipse((x - width, y - height, x + width, y + height), fill=rgba(tone, alpha))
    for _ in range(42):
        x = rng.randint(20, 1060)
        y = rng.randint(1490, 1880)
        rock = rng.randint(8, 32)
        draw.polygon(((x - rock, y + rock // 3), (x - rock // 2, y - rock // 3),
                      (x + rock // 2, y - rock // 2), (x + rock, y + rock // 3)),
                     fill=rgba(lerp_color(ground, (170, 170, 145), 0.38), rng.randint(90, 175)))
    for _ in range(36):
        x = rng.randint(10, 1070)
        y = rng.randint(1520, 1880)
        blade = rng.randint(10, 30)
        draw.line((x, y + 16, x - 8, y - blade), fill=rgba(lerp_color(ground, accent, 0.4), 150), width=3)
        draw.line((x, y + 16, x + 9, y - blade // 2), fill=rgba(lerp_color(ground, accent, 0.55), 130), width=3)


def draw_motif(draw: ImageDraw.ImageDraw, motif: str, accent: tuple[int, int, int], width: int) -> None:
    ink = rgba(accent, 75)
    bright = rgba(accent, 140)
    if motif == "temple":
        for x in (130, 430, 730):
            draw.rectangle((x, 1000, x + 42, 1360), fill=ink)
            draw.rectangle((x - 12, 980, x + 54, 1010), fill=bright)
            draw.polygon(((x - 28, 980), (x + 70, 980), (x + 48, 948), (x - 6, 948)), fill=bright)
            draw.line((x - 5, 1040, x - 5, 1350), fill=rgba(accent, 150), width=5)
    elif motif in ("castle", "fortress"):
        x = int(width * 0.69)
        draw.rectangle((x, 1000, x + 250, 1370), fill=ink)
        for i in range(3):
            draw.rectangle((x - 12 + i * 88, 930, x + 44 + i * 88, 1010), fill=bright)
    elif motif == "arches":
        for x in (190, 510, 830):
            draw.arc((x - 95, 1000, x + 95, 1220), 180, 360, fill=bright, width=18)
            draw.line((x - 95, 1110, x - 95, 1380), fill=ink, width=22)
            draw.line((x + 95, 1110, x + 95, 1380), fill=ink, width=22)
    elif motif == "factory":
        for x, h in ((110, 240), (420, 330), (760, 280)):
            draw.rectangle((x, 1080, x + 190, 1390), fill=ink)
            draw.rectangle((x + 48, 830 - h // 5, x + 82, 1100), fill=bright)
            draw.ellipse((x + 28, 760 - h // 5, x + 102, 850 - h // 5), fill=rgba(accent, 40))
    elif motif == "lightning":
        for x in (270, 730):
            points = ((x, 320), (x - 45, 610), (x + 12, 580), (x - 36, 920))
            draw.line(points, fill=bright, width=14, joint="curve")
    elif motif == "atom":
        center = (800, 570)
        draw.ellipse((center[0] - 26, center[1] - 26, center[0] + 26, center[1] + 26), fill=bright)
        for angle in (0, 60, 120):
            draw.ellipse((center[0] - 180, center[1] - 60, center[0] + 180, center[1] + 60), outline=ink, width=8)
            draw = draw
    elif motif == "grid":
        for x in range(0, width, 150):
            draw.line((x, 300, x, 1290), fill=ink, width=3)
        for y in range(360, 1300, 140):
            draw.line((0, y, width, y), fill=ink, width=3)
    elif motif == "circuit":
        for y in (350, 570, 790, 1010):
            draw.line((70, y, 260, y, 320, y + 55, 760, y + 55), fill=bright, width=7, joint="curve")
            draw.ellipse((750, y + 43, 772, y + 65), fill=bright)
    elif motif == "planet":
        draw.ellipse((700, 360, 960, 620), fill=rgba(accent, 100))
        draw.arc((630, 350, 1030, 650), 185, 350, fill=bright, width=13)
    elif motif == "nebula":
        for x, y, r in ((210, 430, 150), (520, 660, 180), (820, 420, 130)):
            draw.ellipse((x - r, y - r, x + r, y + r), fill=rgba(accent, 30), outline=ink, width=7)
    elif motif == "quantum":
        center = (790, 560)
        draw.ellipse((center[0] - 25, center[1] - 25, center[0] + 25, center[1] + 25), fill=rgba((240, 248, 255), 220))
        for r in (100, 150, 200):
            draw.arc((center[0] - r, center[1] - r, center[0] + r, center[1] + r), 20, 270, fill=bright, width=8)


def background(era_id: str) -> Image.Image:
    top, bottom, accent, ground, motif = ERAS[era_id]
    image = gradient((1080, 1920), top, bottom)
    draw = ImageDraw.Draw(image, "RGBA")
    rng = random.Random(era_id)
    is_space = motif in {"lightning", "atom", "grid", "circuit", "planet", "nebula", "quantum"}
    glow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow, "RGBA")
    glow_center = (820 if is_space else 210, 320 if is_space else 280)
    glow_draw.ellipse((glow_center[0] - 250, glow_center[1] - 250, glow_center[0] + 250, glow_center[1] + 250), fill=rgba(accent, 72))
    image = Image.alpha_composite(image, glow.filter(ImageFilter.GaussianBlur(90)))
    draw = ImageDraw.Draw(image, "RGBA")
    if not is_space:
        cloud_color = rgba(lerp_color(top, (245, 239, 220), 0.58), 58)
        draw_cloud(draw, 190, 270, 1.0, cloud_color)
        draw_cloud(draw, 835, 420, 0.82, rgba(lerp_color(top, (245, 239, 220), 0.64), 45))
    for _ in range(120 if is_space else 35):
        x = rng.randint(0, 1079)
        y = rng.randint(100, 1000)
        r = rng.choice((1, 1, 2, 3))
        draw.ellipse((x - r, y - r, x + r, y + r), fill=rgba((220, 240, 255), rng.randint(60, 180)))
    draw.polygon(((0, 1120), (170, 820), (340, 1110), (540, 700), (760, 1110), (930, 830), (1080, 1100), (1080, 1440), (0, 1440)), fill=rgba(lerp_color(bottom, ground, 0.35), 220))
    draw.polygon(((0, 1260), (160, 970), (340, 1260), (530, 880), (760, 1260), (900, 1000), (1080, 1260), (1080, 1440), (0, 1440)), fill=rgba(ground, 245))
    for x in range(-30, 1120, 110):
        draw_pine(draw, x + rng.randint(-20, 20), 1410, rng.randint(170, 300), rgba(lerp_color(ground, (4, 12, 25), 0.65), 235))
    draw.polygon(((430, 1150), (650, 1150), (930, 1920), (130, 1920)), fill=rgba(lerp_color(ground, (50, 39, 36), 0.4), 245))
    draw.polygon(((510, 1210), (580, 1210), (740, 1920), (340, 1920)), fill=rgba(accent, 55))
    for _ in range(34):
        x = rng.randint(70, 1010)
        y = rng.randint(1440, 1880)
        rock = rng.randint(3, 12)
        draw.ellipse((x - rock, y - rock // 2, x + rock, y + rock // 2), fill=rgba(lerp_color(ground, (235, 206, 150), 0.28), rng.randint(35, 95)))
    draw.line((0, 1400, 1080, 1400), fill=rgba(accent, 115), width=6)
    draw_motif(draw, motif, accent, 1080)
    vignette = Image.new("RGBA", image.size, (0, 0, 0, 0))
    vignette_draw = ImageDraw.Draw(vignette, "RGBA")
    vignette_draw.rectangle((0, 0, 1080, 1920), outline=(2, 5, 14, 165), width=110)
    return Image.alpha_composite(image, vignette)


def actor(kind: str, era_id: str, category: str) -> Image.Image:
    _, _, accent, material, _ = ERAS[era_id]
    size = 170 if kind.startswith("boss") else (120 if kind == "tank" else 96)
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image, "RGBA")
    cx, cy = size // 2, int(size * 0.60)
    rng = random.Random(f"{era_id}:{category}:{kind}")
    if category == "player":
        body = material
        head = (236, 177, 113)
        draw.ellipse((cx - 34, cy + 24, cx + 34, cy + 64), fill=rgba((20, 18, 25), 105))
        draw.ellipse((cx - 18, cy - 54, cx + 18, cy - 18), fill=rgba(head), outline=rgba((55, 32, 25), 255), width=3)
        draw.rounded_rectangle((cx - 28, cy - 20, cx + 28, cy + 30), radius=12, fill=rgba(body), outline=rgba(accent), width=4)
        draw.rounded_rectangle((cx - 18, cy - 8, cx + 18, cy + 2), radius=4, fill=rgba(lerp_color(body, (255, 242, 197), 0.42), 210))
        draw.line((cx - 24, cy + 18, cx + 24, cy + 18), fill=rgba((58, 39, 32), 220), width=5)
        draw.line((cx - 21, cy + 32, cx - 27, cy + 56), fill=rgba((62, 42, 35)), width=8)
        draw.line((cx + 21, cy + 32, cx + 27, cy + 56), fill=rgba((62, 42, 35)), width=8)
        draw.line((cx - 16, cy - 44, cx + 11, cy - 44), fill=rgba((55, 32, 25)), width=6)
        draw.ellipse((cx + 7, cy - 42, cx + 12, cy - 37), fill=rgba((22, 25, 30)))
        if era_id in {"bronze", "iron", "medieval", "industrial", "cybernetic", "space", "interstellar", "quantum"}:
            draw.arc((cx - 25, cy - 63, cx + 25, cy - 8), 180, 360, fill=rgba(accent), width=7)
        draw.line((cx + 28, cy - 9, cx + 50, cy - 42), fill=rgba(accent), width=6)
        return image

    if category == "unit":
        colors = {"militia": material, "archer": (42, 125, 176), "heavy": (100, 105, 135), "crossbow": (155, 95, 45)}
        body = colors.get(kind, material)
        draw.ellipse((cx - 28, cy + 22, cx + 28, cy + 48), fill=rgba((20, 18, 25), 95))
        draw.ellipse((cx - 14, cy - 38, cx + 14, cy - 10), fill=rgba((235, 175, 112)), outline=rgba((53, 35, 28)), width=2)
        draw.rounded_rectangle((cx - 22, cy - 8, cx + 22, cy + 26), radius=9, fill=rgba(body), outline=rgba(accent), width=3)
        draw.line((cx - 17, cy + 9, cx + 17, cy + 9), fill=rgba((248, 225, 170), 155), width=3)
        draw.line((cx - 13, cy + 26, cx - 17, cy + 42), fill=rgba((53, 35, 28)), width=5)
        draw.line((cx + 13, cy + 26, cx + 17, cy + 42), fill=rgba((53, 35, 28)), width=5)
        if kind in {"militia", "heavy"}:
            draw.line((cx + 18, cy - 2, cx + 36, cy - 31), fill=rgba(accent), width=4)
        else:
            draw.arc((cx + 20, cy - 18, cx + 48, cy + 20), 250, 100, fill=rgba(accent), width=4)
        return image

    enemy_colors = {
        "normal": (205, 63, 67), "fast": (239, 153, 51), "tank": (114, 72, 164),
        "ranged": (54, 139, 193), "elite": (227, 185, 54), "berserker": (202, 46, 112),
    }
    body = enemy_colors.get(kind, accent)
    if kind.startswith("boss"):
        body = tuple(min(255, int(value * 0.85 + accent[index] * 0.25)) for index, value in enumerate(body if kind != "boss_chief" else material))
    radius = int(size * (0.25 if kind.startswith("boss") else 0.28))
    draw.ellipse((cx - radius - 10, cy + radius - 2, cx + radius + 10, cy + radius + 18), fill=rgba((10, 8, 18), 115))
    draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill=rgba(body), outline=rgba(accent), width=max(3, size // 28))
    draw.ellipse((cx - radius // 2, cy - radius // 2, cx - radius // 7, cy - radius // 7), fill=rgba((255, 255, 255), 44))
    eye_y = cy - int(radius * 0.18)
    for offset in (-int(radius * 0.38), int(radius * 0.38)):
        draw.ellipse((cx + offset - 5, eye_y - 5, cx + offset + 5, eye_y + 5), fill=rgba((255, 236, 185)))
        draw.ellipse((cx + offset - 2, eye_y - 2, cx + offset + 3, eye_y + 4), fill=rgba((30, 20, 28)))
    if kind in {"tank", "elite"} or kind.startswith("boss"):
        draw.arc((cx - radius - 8, cy - radius - 8, cx + radius + 8, cy + radius + 8), 180, 360, fill=rgba((235, 225, 193)), width=max(4, size // 24))
        draw.line((cx - radius - 5, cy + radius // 3, cx - radius - 22, cy + radius + 18), fill=rgba(accent), width=max(3, size // 30))
        draw.line((cx + radius + 5, cy + radius // 3, cx + radius + 22, cy + radius + 18), fill=rgba(accent), width=max(3, size // 30))
    if kind in {"fast", "berserker"}:
        draw.line((cx - radius - 18, cy - radius // 2, cx - radius + 4, cy - radius // 4), fill=rgba(accent), width=5)
    if kind == "ranged":
        draw.arc((cx + radius // 2, cy - radius, cx + radius + 28, cy + radius), 260, 100, fill=rgba(accent), width=5)
    if kind.startswith("boss"):
        draw.polygon(((cx, cy - radius - 26), (cx - 17, cy - radius + 2), (cx + 17, cy - radius + 2)), fill=rgba(accent))
    for _ in range(3):
        x = rng.randint(max(8, cx - radius), min(size - 8, cx + radius))
        y = rng.randint(max(8, cy - radius), min(size - 8, cy + radius))
        draw.ellipse((x - 3, y - 3, x + 3, y + 3), fill=rgba(accent, 170))
    return image


def pet(era_id: str) -> Image.Image:
    """Single-player companion: recognizable wolf silhouette with era accents."""
    _, _, accent, material, _ = ERAS[era_id]
    size = 132
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image, "RGBA")
    cx, cy = 66, 76
    fur = lerp_color(material, (220, 190, 145), 0.28)
    dark = lerp_color(fur, (24, 20, 28), 0.52)
    light = lerp_color(fur, (255, 245, 220), 0.48)
    # Ground shadow and compact four-legged body.
    draw.ellipse((22, 101, 111, 120), fill=rgba((10, 8, 18), 112))
    draw.ellipse((27, 52, 103, 99), fill=rgba(fur), outline=rgba(accent), width=4)
    draw.polygon(((37, 61), (24, 22), (53, 42)), fill=rgba(dark), outline=rgba(accent), width=3)
    draw.polygon(((80, 43), (108, 20), (96, 64)), fill=rgba(dark), outline=rgba(accent), width=3)
    draw.ellipse((40, 29, 91, 82), fill=rgba(fur), outline=rgba(accent), width=4)
    draw.polygon(((69, 63), (103, 68), (92, 88), (65, 82)), fill=rgba(light), outline=rgba(dark), width=3)
    draw.ellipse((76, 70, 84, 78), fill=rgba((28, 20, 24)))
    draw.ellipse((50, 48, 59, 58), fill=rgba((255, 237, 178)))
    draw.ellipse((54, 50, 59, 57), fill=rgba((22, 20, 28)))
    draw.ellipse((74, 48, 83, 58), fill=rgba((255, 237, 178)))
    draw.ellipse((75, 50, 81, 57), fill=rgba((22, 20, 28)))
    draw.line((37, 95, 31, 111), fill=rgba(dark), width=8)
    draw.line((55, 97, 51, 113), fill=rgba(dark), width=8)
    draw.line((82, 97, 86, 113), fill=rgba(dark), width=8)
    draw.line((99, 90, 117, 73), fill=rgba(dark), width=9)
    draw.line((38, 77, 80, 82), fill=rgba(accent), width=6)
    # Futuristic eras get a luminous collar, earlier eras a warm leather collar.
    if era_id in {"electrical", "digital", "cybernetic", "space", "interstellar", "quantum"}:
        draw.line((38, 77, 80, 82), fill=rgba((235, 250, 255), 235), width=3)
        draw.ellipse((55, 77, 65, 87), fill=rgba(accent), outline=rgba((245, 250, 255)), width=2)
    else:
        draw.ellipse((55, 77, 65, 87), fill=rgba(accent), outline=rgba((70, 42, 28)), width=2)
    return image


def base(era_id: str) -> Image.Image:
    _, _, accent, material, _ = ERAS[era_id]
    image = Image.new("RGBA", (340, 150), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image, "RGBA")
    draw.rounded_rectangle((8, 32, 332, 142), radius=14, fill=rgba(material), outline=rgba(accent), width=6)
    draw.rectangle((22, 18, 318, 50), fill=rgba(accent, 210), outline=rgba((240, 230, 190)), width=3)
    for x in range(35, 315, 48):
        draw.rectangle((x, 58, x + 28, 88), fill=rgba(lerp_color(material, (240, 240, 220), 0.35)), outline=rgba(accent, 150), width=2)
    draw.rectangle((142, 92, 198, 142), fill=rgba((35, 25, 30)), outline=rgba(accent), width=3)
    draw.ellipse((162, 108, 178, 124), fill=rgba((255, 222, 117), 200))
    draw.line((300, 10, 300, 72), fill=rgba((245, 236, 195)), width=4)
    draw.polygon(((300, 12), (326, 22), (300, 33)), fill=rgba(accent))
    return image


def projectile(era_id: str) -> Image.Image:
    _, _, accent, _, _ = ERAS[era_id]
    image = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image, "RGBA")
    draw.ellipse((12, 12, 36, 36), fill=rgba(accent), outline=rgba((245, 240, 210)), width=3)
    draw.line((4, 42, 18, 28), fill=rgba(accent, 100), width=4)
    return image


def main() -> None:
    for era_id in ERAS:
        folder = OUT / era_id
        (folder / "enemies").mkdir(parents=True, exist_ok=True)
        (folder / "units").mkdir(parents=True, exist_ok=True)
        background(era_id).save(folder / "background.png", optimize=True)
        actor("player", era_id, "player").save(folder / "player.png", optimize=True)
        base(era_id).save(folder / "base.png", optimize=True)
        projectile(era_id).save(folder / "projectile.png", optimize=True)
        for kind in ENEMY_KINDS:
            actor(kind, era_id, "enemy").save(folder / "enemies" / f"{kind}.png", optimize=True)
        for kind in UNIT_KINDS:
            actor(kind, era_id, "unit").save(folder / "units" / f"{kind}.png", optimize=True)
        pet_folder = ROOT / "assets" / "pets" / "wolf"
        pet_folder.mkdir(parents=True, exist_ok=True)
        pet(era_id).save(pet_folder / f"{era_id}.png", optimize=True)
    print(f"Generated era art in {OUT}")


if __name__ == "__main__":
    main()
