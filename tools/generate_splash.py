from pathlib import Path

from PIL import Image, ImageDraw


def main() -> None:
    output = Path(__file__).resolve().parents[1] / "assets" / "ui" / "splash.png"
    output.parent.mkdir(parents=True, exist_ok=True)
    image = Image.new("RGB", (512, 512), "#121a29")
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((8, 8, 504, 504), radius=92, fill="#121a29")
    draw.ellipse((142, 110, 370, 338), outline="#3f8cff", width=34)
    draw.line((120, 400, 392, 400), fill="#e8b13c", width=34)
    image.save(output, format="PNG", optimize=True)
    print(output)


if __name__ == "__main__":
    main()
