from PIL import Image, ImageDraw
import os
ROOT = r"D:\APK\age-loop\assets"
def save(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, "PNG")
    print(f"saved {os.path.basename(path)}")

def player_side():
    s=96
    img=Image.new("RGBA",(s,s),(0,0,0,0))
    d=ImageDraw.Draw(img)
    d.ellipse([8,78,88,90], fill=(0,0,0,35))
    # legs side
    d.rounded_rectangle([28,66,40,82], radius=5, fill=(101,67,33), outline=(60,40,20), width=2)
    d.rounded_rectangle([42,66,54,82], radius=5, fill=(101,67,33), outline=(60,40,20), width=2)
    # body side tunic
    d.rounded_rectangle([24,36,62,70], radius=10, fill=(139,90,43), outline=(80,55,30), width=2)
    d.rectangle([24,44,62,52], fill=(160,110,60))
    # arm with club forward
    d.rounded_rectangle([50,42,78,52], radius=5, fill=(255,218,170), outline=(180,140,100), width=2)
    # club handle
    d.rectangle([76,38,80,54], fill=(110,85,55), outline=(70,50,30), width=1)
    # club head
    d.ellipse([76,34,90,56], fill=(210,190,160), outline=(130,110,90), width=2)
    d.ellipse([80,38,86,46], fill=(230,210,180))
    # head side profile facing right
    d.ellipse([36,14,68,44], fill=(255,218,170), outline=(180,140,100), width=2)
    # hair side
    d.ellipse([36,12,68,32], fill=(58,38,28), outline=(35,25,15), width=1)
    # eye side
    d.ellipse([54,22,62,30], fill=(255,255,255), outline=(60,40,20), width=1)
    d.ellipse([57,24,60,28], fill=(40,20,10))
    d.ellipse([58,25,59,26], fill=(255,255,255))
    # nose side
    d.polygon([(68,26),(72,30),(68,34)], fill=(230,185,145), outline=(180,140,100), width=1)
    save(img, os.path.join(ROOT,"characters/player.png"))

def enemy_side(name, size, base, outline, accent):
    img=Image.new("RGBA",(size,size),(0,0,0,0))
    d=ImageDraw.Draw(img)
    pad=4
    d.ellipse([pad, size-14, size-pad, size-6], fill=(0,0,0,38))
    # body side
    d.rounded_rectangle([pad+6, pad+8, size-pad-10, size-18], radius=size//8, fill=base, outline=outline, width=3)
    # chest highlight
    d.rounded_rectangle([pad+10, pad+12, size-pad-14, pad+28], radius=6, fill=(255,255,255,30))
    # head side facing right (will be flipped for enemies to face left)
    hx, hy = size*0.55, size*0.24
    d.ellipse([hx-18, hy-12, hx+18, hy+16], fill=(255,218,170) if name in ["normal","fast"] else accent, outline=outline, width=2)
    # helmet for elite etc - simpler keep same
    # eye
    d.ellipse([hx+4, hy-2, hx+14, hy+6], fill=(255,255,255), outline=(40,20,10), width=1)
    d.ellipse([hx+8, hy, hx+12, hy+4], fill=(0,0,0))
    # arm forward
    d.rounded_rectangle([size*0.42, size*0.36, size*0.72, size*0.48], radius=5, fill=base, outline=outline, width=2)
    # weapon
    if name in ["ranged","elite"]:
        # bow
        d.arc([size*0.62,size*0.30,size*0.88,size*0.56], 260, 100, fill=(120,80,40), width=3)
        d.line([(size*0.75,size*0.34),(size*0.75,size*0.52)], fill=(220,200,160), width=2)
    elif name in ["tank","normal","berserker"]:
        # axe/club
        d.rectangle([size*0.68,size*0.32,size*0.74,size*0.52], fill=(110,85,55), outline=(70,50,30), width=1)
        d.ellipse([size*0.64,size*0.28,size*0.80,size*0.40], fill=(180,180,190), outline=(100,100,110), width=2)
    # legs side walking
    d.rounded_rectangle([size*0.22,size*0.62,size*0.36,size*0.82], radius=5, fill=base, outline=outline, width=2)
    d.rounded_rectangle([size*0.34,size*0.62,size*0.48,size*0.82], radius=5, fill=base, outline=outline, width=2)
    save(img, os.path.join(ROOT,f"enemies/{name}.png"))

def boss_side(name, size, base, outline, accent):
    img=Image.new("RGBA",(size,size),(0,0,0,0))
    d=ImageDraw.Draw(img)
    pad=10
    d.ellipse([pad, size-22, size-pad, size-8], fill=(0,0,0,45))
    d.rounded_rectangle([pad,pad+16,size-pad,size-22], radius=18, fill=base, outline=outline, width=4)
    d.rounded_rectangle([size*0.18,size*0.36,size*0.78,size*0.66], radius=10, fill=accent, outline=outline, width=2)
    # head side large
    hx = size*0.62
    d.ellipse([hx-28, size*0.14, hx+28, size*0.34], fill=(255,218,170) if name=="boss_mamut" else accent, outline=outline, width=3)
    d.ellipse([hx+8, size*0.20, hx+22, size*0.26], fill=(255,255,255), outline=(40,20,10), width=1)
    d.ellipse([hx+12, size*0.22, hx+18, size*0.25], fill=(0,0,0))
    if name=="boss_mamut":
        d.arc([size*0.50,size*0.24,size*0.72,size*0.48], 120, 260, fill=(245,235,220), width=size//20)
        d.ellipse([hx-18,size*0.28,hx+10,size*0.38], fill=(130,80,50), outline=outline, width=2)
    elif name=="boss_chief":
        for i, col in enumerate([(200,60,60),(240,180,40),(60,160,80)]):
            x=size*0.30+i*size*0.14
            d.ellipse([x-10, pad+2, x+10, pad+22], fill=col, outline=(80,40,20), width=2)
    elif name=="boss_iron_general":
        d.rounded_rectangle([hx-26, size*0.12, hx+26, size*0.22], radius=6, fill=(90,100,115), outline=(60,65,75), width=2)
        d.rectangle([hx-16, size*0.20, hx+16, size*0.24], fill=(200,40,40), outline=(120,20,20), width=1)
    # arm with weapon
    d.rounded_rectangle([size*0.48,size*0.38,size*0.78,size*0.50], radius=8, fill=base, outline=outline, width=2)
    save(img, os.path.join(ROOT,f"enemies/{name}.png"))

def unit_side(name, col):
    s=60
    img=Image.new("RGBA",(s,s),(0,0,0,0))
    d=ImageDraw.Draw(img)
    d.ellipse([6,44,54,52], fill=(0,0,0,35))
    d.rounded_rectangle([8,12,42,44], radius=8, fill=col, outline=tuple(c-40 for c in col[:3])+(255,), width=2)
    d.ellipse([28,10,48,28], fill=(255,220,180), outline=(180,140,100), width=1)
    d.ellipse([38,16,44,22], fill=(255,255,255))
    d.ellipse([40,18,43,21], fill=(0,0,0))
    if name=="archer":
        d.arc([36,26,54,40], 260, 100, fill=(120,80,40), width=2)
    elif name=="heavy":
        d.ellipse([38,26,52,42], fill=(185,185,195), outline=(100,100,110), width=2)
    elif name=="crossbow":
        d.rectangle([36,28,52,32], fill=(90,70,40), outline=(60,50,30), width=1)
    save(img, os.path.join(ROOT,f"units/{name}.png"))

def icons():
    for name, col, sym in [("gold",(230,180,40),"●"),("science",(80,160,220),"◆"),("materials",(160,160,170),"■")]:
        s=48
        img=Image.new("RGBA",(s,s),(0,0,0,0))
        d=ImageDraw.Draw(img)
        # glow
        d.ellipse([2,2,46,46], fill=col+(60,))
        d.ellipse([6,6,42,42], fill=col, outline=(255,255,255), width=2)
        d.ellipse([14,10,26,22], fill=(255,255,255,120))
        # symbol
        d.text((18,14), sym, fill=(255,255,255), font=None)
        save(img, os.path.join(ROOT,f"ui/icons/{name}.png"))

if __name__=="__main__":
    player_side()
    for n, base, out, acc in [
        ("normal",(200,60,60),(120,30,30),(180,40,40)),
        ("fast",(240,160,40),(180,110,20),(255,200,80)),
        ("tank",(130,70,180),(80,40,120),(160,100,200)),
        ("ranged",(70,150,200),(40,100,150),(90,170,220)),
        ("berserker",(220,40,40),(140,20,20),(240,80,80)),
        ("elite",(220,190,40),(150,120,20),(240,210,80)),
    ]:
        enemy_side(n, {"normal":72,"fast":56,"tank":96,"ranged":64,"berserker":70,"elite":80}[n], base, out, acc)
    for n, base, out, acc in [
        ("boss_mamut",(140,95,60),(90,60,40),(160,110,70)),
        ("boss_chief",(180,80,45),(110,50,30),(210,150,110)),
        ("boss_iron_general",(110,120,135),(70,75,85),(140,150,165)),
    ]:
        boss_side(n, {"boss_mamut":150,"boss_chief":170,"boss_iron_general":190}[n], base, out, acc)
    for n, col in [("archer",(70,130,180)),("heavy",(120,120,130)),("crossbow",(160,120,80))]:
        unit_side(n, col)
    icons()
    print("side polished done")
