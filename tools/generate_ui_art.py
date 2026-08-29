from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "ui"
UNITS_OUT = ROOT / "assets" / "units"
SIZE = (1080, 1920)


def gradient(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    image = Image.new("RGBA", size)
    pixels = image.load()
    height = size[1] - 1
    for y in range(size[1]):
        t = y / height
        color = tuple(int(top[i] * (1.0 - t) + bottom[i] * t) for i in range(3)) + (255,)
        for x in range(size[0]):
            pixels[x, y] = color
    return image


def cloud(layer: Image.Image, center: tuple[int, int], scale: float, color: tuple[int, int, int, int]) -> None:
    draw = ImageDraw.Draw(layer)
    cx, cy = center
    blobs = [(-105, 18, 135, 62), (-55, -28, 145, 94), (20, -62, 125, 112), (100, -6, 145, 72), (160, 26, 100, 48)]
    for dx, dy, rx, ry in blobs:
        box = ((cx + (dx - rx) * scale, cy + (dy - ry) * scale), (cx + (dx + rx) * scale, cy + (dy + ry) * scale))
        draw.ellipse(box, fill=color)


def pine(draw: ImageDraw.ImageDraw, x: float, y: float, height: float, color: tuple[int, int, int, int]) -> None:
    width = height * 0.38
    draw.rectangle((x - width * 0.035, y - height * 0.12, x + width * 0.035, y + 12), fill=(55, 48, 38, 255))
    for index, ratio in enumerate((0.2, 0.43, 0.66, 0.88)):
        tip_y = y - height * ratio
        half = width * (0.22 + index * 0.11)
        draw.polygon(((x, tip_y), (x - half, y - height * (ratio - 0.19)), (x + half, y - height * (ratio - 0.19))), fill=color)


def vignette(image: Image.Image, strength: int = 150) -> Image.Image:
    overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    pixels = overlay.load()
    cx, cy = image.width / 2, image.height / 2
    max_distance = math.sqrt(cx * cx + cy * cy)
    for y in range(image.height):
        for x in range(image.width):
            distance = math.sqrt((x - cx) ** 2 + (y - cy) ** 2) / max_distance
            alpha = int(max(0.0, distance - 0.28) / 0.72 * strength)
            pixels[x, y] = (4, 10, 20, min(alpha, 210))
    return Image.alpha_composite(image, overlay)


def menu_background() -> Image.Image:
    image = gradient(SIZE, (24, 77, 122), (61, 112, 82))
    draw = ImageDraw.Draw(image, "RGBA")

    glow = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow, "RGBA")
    glow_draw.ellipse((720, 150, 1190, 620), fill=(255, 202, 116, 52))
    glow = glow.filter(ImageFilter.GaussianBlur(72))
    image = Image.alpha_composite(image, glow)
    draw = ImageDraw.Draw(image, "RGBA")
    draw.ellipse((820, 245, 990, 415), fill=(255, 221, 145, 220))

    clouds = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    cloud(clouds, (120, 260), 1.15, (233, 240, 235, 172))
    cloud(clouds, (860, 300), 1.3, (248, 242, 222, 188))
    cloud(clouds, (500, 120), 0.62, (205, 229, 235, 95))
    clouds = clouds.filter(ImageFilter.GaussianBlur(9))
    image = Image.alpha_composite(image, clouds)
    draw = ImageDraw.Draw(image, "RGBA")

    # Montañas lejanas y bosque para dar profundidad detrás del menú.
    draw.polygon(((0, 890), (170, 650), (310, 835), (480, 540), (690, 850), (850, 590), (1080, 850), (1080, 1250), (0, 1250)), fill=(73, 114, 126, 220))
    draw.polygon(((0, 1030), (230, 760), (375, 930), (595, 700), (770, 950), (920, 710), (1080, 1010), (1080, 1370), (0, 1370)), fill=(35, 79, 82, 245))
    draw.polygon(((0, 1160), (150, 1010), (280, 1120), (450, 940), (640, 1130), (820, 960), (1080, 1140), (1080, 1520), (0, 1520)), fill=(25, 69, 58, 255))

    rng = random.Random(17)
    for row, (base_y, color, h_min, h_max) in enumerate(((1210, (18, 57, 52, 255), 105, 185), (1380, (11, 43, 39, 255), 135, 240))):
        for x in range(-35, 1120, 58):
            pine(draw, x + rng.randint(-16, 16), base_y + rng.randint(-18, 18), rng.randint(h_min, h_max), color)

    # Camino y claros inferiores, dejando el centro con aire para el logo.
    draw.polygon(((448, 1210), (640, 1210), (895, 1920), (165, 1920)), fill=(43, 57, 48, 220))
    draw.polygon(((505, 1310), (590, 1310), (730, 1920), (340, 1920)), fill=(81, 80, 57, 125))

    # Castillo estilizado en segundo plano.
    castle = (198, 108, 78, 255)
    stone = (226, 164, 108, 255)
    draw.rectangle((205, 1010, 432, 1235), fill=castle)
    draw.rectangle((245, 885, 310, 1120), fill=stone)
    draw.rectangle((352, 920, 417, 1120), fill=stone)
    draw.polygon(((230, 890), (278, 815), (325, 890)), fill=(86, 53, 62, 255))
    draw.polygon(((338, 925), (384, 850), (431, 925)), fill=(86, 53, 62, 255))
    draw.rectangle((270, 1120, 370, 1235), fill=(83, 51, 40, 255))
    draw.ellipse((307, 1135, 333, 1161), fill=(245, 190, 93, 190))
    for x in (255, 365):
        draw.rectangle((x, 946, x + 17, 1010), fill=(31, 61, 64, 255))
        draw.rectangle((x + 34, 946, x + 51, 1010), fill=(31, 61, 64, 255))

    # Rocas/vegetación de primer plano.
    for x, y, r in ((45, 1640, 100), (1000, 1720, 130), (180, 1835, 78), (870, 1880, 92)):
        draw.ellipse((x - r, y - r * 0.55, x + r, y + r * 0.55), fill=(15, 42, 39, 255), outline=(92, 111, 76, 130), width=5)
    for x in (34, 1018):
        draw.line((x, 1690, x, 1920), fill=(22, 48, 38, 255), width=24)
        for offset in (-24, 24):
            draw.line((x, 1770 + offset, x + offset * 2, 1725 + offset), fill=(31, 69, 49, 230), width=12)
    return vignette(image, 168)


def battle_background() -> Image.Image:
    image = gradient(SIZE, (5, 15, 35), (21, 38, 47))
    draw = ImageDraw.Draw(image, "RGBA")
    rng = random.Random(42)
    for _ in range(90):
        x = rng.randint(20, 1060)
        y = rng.randint(120, 980)
        r = rng.choice((1, 1, 2, 3))
        draw.ellipse((x - r, y - r, x + r, y + r), fill=(163, 198, 204, rng.randint(70, 180)))
    draw.ellipse((760, 160, 900, 300), fill=(205, 226, 217, 170))
    draw.ellipse((790, 185, 930, 325), fill=(8, 20, 43, 235))

    draw.polygon(((0, 1030), (185, 770), (355, 1030), (540, 680), (735, 1030), (915, 790), (1080, 1030), (1080, 1395), (0, 1395)), fill=(17, 40, 58, 255))
    draw.polygon(((0, 1180), (160, 930), (315, 1190), (500, 855), (705, 1190), (865, 900), (1080, 1160), (1080, 1420), (0, 1420)), fill=(11, 29, 40, 255))

    for x, h in ((45, 300), (120, 250), (220, 330), (860, 300), (960, 260), (1045, 355)):
        pine(draw, x, 1390, h, (8, 34, 34, 255))
    for x in range(-20, 1120, 92):
        if 300 < x < 780:
            continue
        pine(draw, x + rng.randint(-20, 20), 1390, rng.randint(170, 270), (12, 45, 42, 235))

    draw.polygon(((455, 1120), (625, 1120), (920, 1920), (140, 1920)), fill=(62, 62, 49, 255))
    draw.polygon(((500, 1170), (580, 1170), (730, 1920), (335, 1920)), fill=(110, 83, 55, 110))
    draw.line((0, 1380, 1080, 1380), fill=(161, 120, 67, 140), width=6)

    # Entrada de madera y faroles, con lectura clara en el lado de la base.
    draw.rectangle((32, 1010, 188, 1390), fill=(33, 50, 42, 255), outline=(111, 90, 57, 255), width=7)
    for x in (48, 98, 148):
        draw.line((x, 1040, x, 1365), fill=(102, 73, 48, 255), width=7)
    draw.polygon(((30, 1010), (110, 950), (190, 1010)), fill=(77, 67, 48, 255))
    for x in (218, 890):
        draw.line((x, 1230, x, 1380), fill=(115, 74, 37, 255), width=9)
        draw.ellipse((x - 22, 1175, x + 22, 1234), fill=(255, 166, 45, 220))
        draw.ellipse((x - 10, 1188, x + 10, 1220), fill=(255, 237, 145, 255))
    return vignette(image, 120)


def icon(name: str, color: tuple[int, int, int]) -> Image.Image:
    size = 96
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image, "RGBA")
    gold = (221, 170, 67, 255)
    dark = (35, 29, 27, 255)
    light = (241, 224, 177, 255)
    draw.ellipse((8, 8, 88, 88), fill=(17, 24, 31, 220), outline=gold, width=4)
    if name == "play":
        draw.polygon(((39, 26), (70, 48), (39, 70)), fill=(93, 198, 100, 255), outline=light)
    elif name == "inventory":
        draw.rounded_rectangle((20, 32, 76, 72), radius=8, fill=(153, 93, 42, 255), outline=light, width=3)
        draw.arc((31, 18, 65, 48), 180, 360, fill=light, width=5)
        draw.rectangle((45, 47, 52, 58), fill=gold)
    elif name == "book":
        draw.polygon(((20, 28), (46, 34), (46, 74), (20, 68)), fill=(154, 88, 44, 255), outline=light)
        draw.polygon(((50, 34), (76, 28), (76, 68), (50, 74)), fill=(192, 124, 58, 255), outline=light)
        draw.line((48, 34, 48, 74), fill=gold, width=4)
    elif name == "castle":
        draw.rectangle((24, 38, 72, 72), fill=(170, 180, 182, 255), outline=light, width=3)
        for x in (25, 44, 63):
            draw.rectangle((x, 27, x + 12, 40), fill=(205, 208, 196, 255), outline=light, width=2)
        draw.rectangle((43, 54, 54, 72), fill=dark)
    elif name == "gear":
        draw.ellipse((28, 28, 68, 68), outline=light, width=10)
        for angle in range(0, 360, 45):
            a = math.radians(angle)
            x, y = 48 + math.cos(a) * 28, 48 + math.sin(a) * 28
            draw.rectangle((x - 5, y - 5, x + 5, y + 5), fill=light)
        draw.ellipse((41, 41, 55, 55), fill=gold)
    elif name == "sword":
        draw.line((28, 70, 70, 28), fill=light, width=10)
        draw.polygon(((65, 25), (76, 20), (72, 37)), fill=(190, 205, 218, 255))
        draw.line((25, 62, 40, 77), fill=gold, width=8)
        draw.line((20, 58, 38, 76), fill=dark, width=4)
    elif name == "shield":
        draw.polygon(((25, 25), (71, 25), (68, 61), (48, 78), (28, 61)), fill=(82, 128, 158, 255), outline=light)
        draw.line((48, 32, 48, 66), fill=light, width=5)
        draw.line((34, 49, 62, 49), fill=light, width=5)
    elif name == "fury":
        draw.polygon(((48, 20), (58, 39), (78, 42), (63, 55), (67, 76), (48, 65), (29, 76), (33, 55), (18, 42), (38, 39)), fill=(218, 77, 51, 255), outline=(255, 206, 120, 255))
    elif name == "ring":
        draw.ellipse((27, 31, 69, 78), outline=(218, 178, 72, 255), width=9)
        draw.ellipse((36, 39, 60, 66), outline=(238, 218, 140, 255), width=3)
        draw.polygon(((35, 31), (48, 15), (61, 31), (48, 39)), fill=(116, 191, 231, 255), outline=light)
    return image


def unit_sprite(kind: str) -> Image.Image:
    """Small readable battle sprites with transparent backgrounds."""
    scale = 4
    image = Image.new("RGBA", (72 * scale, 72 * scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image, "RGBA")

    def box(coords: tuple[int, int, int, int], radius: int, fill: tuple[int, int, int, int], outline: tuple[int, int, int, int] | None = None, width: int = 1) -> None:
        scaled = tuple(value * scale for value in coords)
        draw.rounded_rectangle(scaled, radius=radius * scale, fill=fill, outline=outline, width=width * scale)

    # Feet and a compact, high-contrast body silhouette.
    box((22, 48, 34, 62), 4, (73, 45, 29, 255))
    box((39, 48, 51, 62), 4, (73, 45, 29, 255))
    if kind == "militia":
        box((14, 27, 54, 53), 9, (137, 80, 38, 255), (248, 204, 118, 255), 2)
        draw.line((18 * scale, 34 * scale, 50 * scale, 46 * scale), fill=(181, 111, 48, 255), width=3 * scale)
        draw.line((54 * scale, 8 * scale, 44 * scale, 55 * scale), fill=(208, 167, 103, 255), width=3 * scale)
        draw.polygon(((53 * scale, 8 * scale), (59 * scale, 16 * scale), (49 * scale, 17 * scale)), fill=(225, 235, 214, 255))
    elif kind == "archer":
        box((14, 27, 54, 53), 9, (48, 116, 165, 255), (187, 225, 240, 255), 2)
        draw.arc((49 * scale, 25 * scale, 72 * scale, 54 * scale), 260, 100, fill=(226, 182, 91, 255), width=3 * scale)
        draw.line((59 * scale, 26 * scale, 59 * scale, 54 * scale), fill=(226, 182, 91, 255), width=2 * scale)
    else:
        box((14, 27, 54, 53), 9, (92, 94, 117, 255), (226, 232, 244, 255), 2)
        draw.line((23 * scale, 32 * scale, 50 * scale, 49 * scale), fill=(210, 221, 230, 255), width=4 * scale)

    draw.ellipse((23 * scale, 8 * scale, 49 * scale, 34 * scale), fill=(240, 185, 119, 255), outline=(78, 45, 31, 255), width=2 * scale)
    draw.pieslice((21 * scale, 6 * scale, 51 * scale, 25 * scale), 180, 350, fill=(65, 43, 31, 255))
    draw.ellipse((40 * scale, 18 * scale, 44 * scale, 22 * scale), fill=(24, 29, 34, 255))
    draw.line((31 * scale, 31 * scale, 38 * scale, 31 * scale), fill=(85, 43, 31, 255), width=2 * scale)
    return image.resize((72, 72), Image.Resampling.LANCZOS)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    UNITS_OUT.mkdir(parents=True, exist_ok=True)
    menu_background().convert("RGB").save(OUT / "menu_background.png", optimize=True)
    battle_background().convert("RGB").save(OUT / "battle_background.png", optimize=True)
    for name, color in (("play", (90, 200, 100)), ("inventory", (170, 112, 48)), ("book", (170, 105, 52)), ("castle", (185, 188, 180)), ("gear", (176, 180, 185)), ("sword", (180, 205, 224)), ("shield", (90, 150, 190)), ("fury", (220, 74, 48)), ("ring", (218, 178, 72))):
        icon(name, color).save(OUT / "icons" / f"{name}.png", optimize=True)
    for kind in ("militia", "archer", "heavy"):
        unit_sprite(kind).save(UNITS_OUT / f"{kind}.png", optimize=True)
    print("Generated illustrated UI art in", OUT)


if __name__ == "__main__":
    main()
