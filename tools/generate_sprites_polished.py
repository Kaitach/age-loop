from PIL import Image, ImageDraw
import os
ROOT = r"D:\APK\age-loop\assets"
def ensure_dir(p): os.makedirs(p, exist_ok=True)
def save(img, path):
    ensure_dir(os.path.dirname(path))
    img.save(path, "PNG")
    print(f"saved {os.path.basename(path)} {img.size}")

def highlight_ellipse(draw, bbox, fill=(255,255,255,90)):
    draw.ellipse(bbox, fill=fill)

def player_polished():
    s=96
    img=Image.new("RGBA",(s,s),(0,0,0,0))
    d=ImageDraw.Draw(img)
    # soft shadow
    d.ellipse([10,78,86,90], fill=(0,0,0,35))
    # legs
    d.rounded_rectangle([30,68,44,82], radius=5, fill=(101,67,33), outline=(60,40,20), width=2)
    d.rounded_rectangle([52,68,66,82], radius=5, fill=(101,67,33), outline=(60,40,20), width=2)
    # body tunic with fur
    d.rounded_rectangle([18,36,78,74], radius=14, fill=(139,90,43), outline=(80,55,30), width=3)
    d.rounded_rectangle([20,38,76,58], radius=10, fill=(160,110,60), outline=(100,70,35), width=1)
    # fur collar highlight
    d.ellipse([22,30,74,50], fill=(232,210,170), outline=(140,110,80), width=2)
    highlight_ellipse(d, [28,34,50,44], fill=(255,255,255,70))
    # belt
    d.rectangle([22,58,74,64], fill=(80,50,30), outline=(50,30,15), width=1)
    d.ellipse([44,56,52,66], fill=(200,180,120), outline=(120,100,60), width=1)
    # head
    d.ellipse([28,10,68,46], fill=(255,218,170), outline=(180,140,100), width=2)
    highlight_ellipse(d, [32,14,48,28], fill=(255,255,255,80))
    # hair top
    d.ellipse([28,8,68,30], fill=(58,38,28), outline=(35,25,15), width=2)
    d.ellipse([30,12,42,24], fill=(70,45,30))
    d.ellipse([54,12,66,24], fill=(70,45,30))
    # eyes
    d.ellipse([36,24,44,32], fill=(255,255,255), outline=(60,40,20), width=1)
    d.ellipse([52,24,60,32], fill=(255,255,255), outline=(60,40,20), width=1)
    d.ellipse([39,27,42,30], fill=(40,20,10))
    d.ellipse([55,27,58,30], fill=(40,20,10))
    d.ellipse([40,28,41,29], fill=(255,255,255))
    d.ellipse([56,28,57,29], fill=(255,255,255))
    # brows angry
    d.line([(34,22),(46,24)], fill=(60,30,15), width=2)
    d.line([(62,22),(50,24)], fill=(60,30,15), width=2)
    # nose
    d.ellipse([44,30,52,36], fill=(230,185,145), outline=(180,140,100), width=1)
    # mouth
    d.arc([41,34,55,40], 15, 165, fill=(120,50,30), width=2)
    # club
    d.rounded_rectangle([64,4,72,30], radius=4, fill=(110,85,55), outline=(70,50,30), width=2)
    d.ellipse([58,0,78,16], fill=(210,190,160), outline=(130,110,90), width=2)
    d.ellipse([62,4,74,12], fill=(230,210,180))
    # highlight on club
    highlight_ellipse(d, [62,3,70,9], fill=(255,255,255,90))
    save(img, os.path.join(ROOT,"characters/player.png"))

def enemy_polished(name, size, base_color, outline, accent, eye_color=(255,255,255)):
    img=Image.new("RGBA",(size,size),(0,0,0,0))
    d=ImageDraw.Draw(img)
    pad=4
    draw_shadow = [pad+2, size-14, size-pad-2, size-8]
    d.ellipse(draw_shadow, fill=(0,0,0,38))
    # body
    d.rounded_rectangle([pad,pad,size-pad,size-16], radius=size//7, fill=base_color, outline=outline, width=3)
    # inner highlight top
    hl_h = size//3
    d.rounded_rectangle([pad+6,pad+4,size-pad-6,pad+hl_h], radius=8, fill=(255,255,255,28))
    # chest plate
    d.rounded_rectangle([size*0.2,size*0.32,size*0.8,size*0.62], radius=6, fill=accent, outline=outline, width=1)
    # rivets
    # eyes
    eye_r = size*0.09
    lx, rx = size*0.22, size*0.62
    ey = size*0.22
    d.ellipse([lx,ey,lx+eye_r*1.4,ey+eye_r*1.2], fill=eye_color, outline=(40,20,10), width=1)
    d.ellipse([rx,ey,rx+eye_r*1.4,ey+eye_r*1.2], fill=eye_color, outline=(40,20,10), width=1)
    d.ellipse([lx+4,ey+4,lx+10,ey+10], fill=(0,0,0))
    d.ellipse([rx+4,ey+4,rx+10,ey+10], fill=(0,0,0))
    d.ellipse([lx+5,ey+5,lx+7,ey+7], fill=(255,255,255))
    d.ellipse([rx+5,ey+5,rx+7,ey+7], fill=(255,255,255))
    # mouth
    d.rounded_rectangle([size*0.30,size*0.54,size*0.70,size*0.64], radius=4, fill=(60,15,15), outline=(40,10,10), width=1)
    d.rectangle([size*0.36,size*0.56,size*0.44,size*0.62], fill=(255,255,255))
    d.rectangle([size*0.56,size*0.56,size*0.64,size*0.62], fill=(255,255,255))
    save(img, os.path.join(ROOT,f"enemies/{name}.png"))

def boss_polished(name, size, base, outline, accent):
    img=Image.new("RGBA",(size,size),(0,0,0,0))
    d=ImageDraw.Draw(img)
    pad=8
    d.ellipse([pad, size-22, size-pad, size-8], fill=(0,0,0,45))
    d.rounded_rectangle([pad,pad+18,size-pad,size-22], radius=20, fill=base, outline=outline, width=4)
    # chest
    d.rounded_rectangle([size*0.18,size*0.38,size*0.82,size*0.68], radius=12, fill=accent, outline=outline, width=2)
    # head area
    head_pad = size*0.18
    d.ellipse([head_pad, pad+6, size-head_pad, size*0.48], fill=accent, outline=outline, width=3)
    highlight_ellipse(d, [head_pad+10, pad+14, head_pad+40, pad+30], fill=(255,255,255,60))
    # eyes large
    er = size*0.07
    d.ellipse([size*0.32,size*0.22,size*0.32+er*1.6,size*0.22+er*1.3], fill=(255,220,120), outline=(80,40,10), width=2)
    d.ellipse([size*0.58,size*0.22,size*0.58+er*1.6,size*0.22+er*1.3], fill=(255,220,120), outline=(80,40,10), width=2)
    d.ellipse([size*0.34,size*0.25,size*0.34+er*0.7,size*0.25+er*0.7], fill=(0,0,0))
    d.ellipse([size*0.60,size*0.25,size*0.60+er*0.7,size*0.25+er*0.7], fill=(0,0,0))
    # extra boss details
    if name=="boss_mamut":
        # tusks
        d.arc([size*0.12,size*0.30,size*0.32,size*0.62], 120, 260, fill=(245,235,220), width=size//18)
        d.arc([size*0.68,size*0.30,size*0.88,size*0.62], 280, 60, fill=(245,235,220), width=size//18)
        d.rounded_rectangle([size*0.42,size*0.38,size*0.58,size*0.72], radius=10, fill=(120,80,50), outline=outline, width=2)
    elif name=="boss_chief":
        for i, col in enumerate([(200,60,60),(240,180,40),(60,160,80)]):
            x=size*0.32+i*size*0.18
            d.ellipse([x-14, pad, x+14, pad+28], fill=col, outline=(80,40,20), width=2)
            highlight_ellipse(d, [x-6, pad+4, x+2, pad+12], fill=(255,255,255,90))
        d.rectangle([size*0.32,size*0.48,size*0.68,size*0.56], fill=(200,40,40))
        d.ellipse([size*0.44,size*0.62,size*0.56,size*0.72], fill=(240,210,80), outline=(150,120,20), width=2)
    elif name=="boss_iron_general":
        for x in [size*0.28,size*0.50,size*0.72]:
            d.ellipse([x-7,size*0.44,x+7,size*0.52], fill=(200,200,210), outline=(100,100,110), width=1)
            highlight_ellipse(d, [x-4,size*0.45,x, size*0.48], fill=(255,255,255,120))
        d.rectangle([size*0.36,size*0.26,size*0.64,size*0.32], fill=(200,40,40), outline=(120,20,20), width=1)
        d.polygon([(pad+6,size*0.30),(2,size*0.92),(pad+18,size*0.86)], fill=(120,20,30), outline=(80,10,20), width=2)
    save(img, os.path.join(ROOT,f"enemies/{name}.png"))

def base_polished():
    w,h=340,150
    img=Image.new("RGBA",(w,h),(0,0,0,0))
    d=ImageDraw.Draw(img)
    d.ellipse([18,h-20,322,h-6], fill=(0,0,0,45))
    # wall base
    d.rounded_rectangle([0,30,w,h], radius=14, fill=(162,168,180), outline=(110,115,125), width=4)
    # stone bricks with shading
    for y in [46,76,106]:
        for x in range(0,w,42):
            # brick
            d.rounded_rectangle([x+4,y, x+38,y+20], radius=4, fill=(185,190,205), outline=(130,135,150), width=1)
            # highlight top
            d.line([(x+6,y+2),(x+36,y+2)], fill=(255,255,255,60), width=1)
    # battlements
    for i in range(4):
        x=10+i*(w//4)
        d.rounded_rectangle([x,8,x+60,30], radius=4, fill=(145,150,165), outline=(110,115,125), width=2)
        d.rectangle([x+14,0,x+46,12], fill=(162,168,180), outline=(110,115,125), width=2)
        highlight_ellipse(d, [x+18,4,x+30,10], fill=(255,255,255,50))
    # gate arch
    d.rounded_rectangle([w//2-36,68,w//2+36,h], radius=10, fill=(70,55,40), outline=(45,35,25), width=3)
    d.rounded_rectangle([w//2-26,88,w//2+26,h], radius=6, fill=(45,35,25), outline=(30,22,15), width=1)
    d.ellipse([w//2-8,98,w//2+8,114], fill=(90,70,50), outline=(60,45,30), width=1)
    # flag
    d.rectangle([w-30,8,w-24,40], fill=(90,80,70), outline=(60,55,50), width=1)
    d.polygon([(w-24,10),(w-64,19),(w-24,28)], fill=(210,60,45), outline=(140,35,25), width=2)
    highlight_ellipse(d, [w-60,14,w-48,20], fill=(255,255,255,70))
    save(img, os.path.join(ROOT,"buildings/base.png"))

def projectile_polished():
    s=26
    img=Image.new("RGBA",(s,s),(0,0,0,0))
    d=ImageDraw.Draw(img)
    # outer glow
    d.ellipse([1,1,25,25], fill=(100,180,255,90))
    d.ellipse([4,4,22,22], fill=(120,200,255,220), outline=(255,255,255), width=2)
    d.ellipse([9,9,17,17], fill=(255,255,255))
    highlight_ellipse(d, [8,6,14,12], fill=(255,255,255,160))
    save(img, os.path.join(ROOT,"projectiles/projectile.png"))

def unit_polished(name, col):
    s=60
    img=Image.new("RGBA",(s,s),(0,0,0,0))
    d=ImageDraw.Draw(img)
    d.ellipse([6,44,54,52], fill=(0,0,0,35))
    d.rounded_rectangle([4,4,56,46], radius=10, fill=col, outline=tuple(c-40 for c in col[:3])+(255,), width=2)
    highlight_ellipse(d, [8,8,28,20], fill=(255,255,255,70))
    # face
    d.ellipse([14,12,46,32], fill=(255,220,180), outline=(180,140,100), width=1)
    d.ellipse([20,18,28,26], fill=(255,255,255))
    d.ellipse([34,18,42,26], fill=(255,255,255))
    d.ellipse([23,21,25,23], fill=(0,0,0))
    d.ellipse([37,21,39,23], fill=(0,0,0))
    if name=="archer":
        d.arc([8,28,48,46], 200, 340, fill=(120,80,40), width=2)
        d.line([(28,30),(28,42)], fill=(220,200,160), width=2)
    elif name=="heavy":
        d.ellipse([12,28,30,48], fill=(185,185,195), outline=(100,100,110), width=2)
        highlight_ellipse(d, [14,30,22,38], fill=(255,255,255,80))
    elif name=="crossbow":
        d.rectangle([10,28,46,34], fill=(90,70,40), outline=(60,50,30), width=1)
        d.ellipse([20,32,28,40], fill=(200,60,40), outline=(140,40,20), width=1)
    save(img, os.path.join(ROOT,f"units/{name}.png"))

if __name__=="__main__":
    player_polished()
    for n, col, out, acc in [
        ("normal", (200,60,60), (120,30,30), (180,40,40)),
        ("fast", (240,160,40), (180,110,20), (255,200,80)),
        ("tank", (130,70,180), (80,40,120), (160,100,200)),
        ("ranged", (70,150,200), (40,100,150), (90,170,220)),
        ("berserker", (220,40,40), (140,20,20), (240,80,80)),
        ("elite", (220,190,40), (150,120,20), (240,210,80)),
    ]:
        enemy_polished(n, {"normal":72,"fast":56,"tank":96,"ranged":64,"berserker":70,"elite":80}[n], col, out, acc)
    for n, col, out, acc in [
        ("boss_mamut", (140,95,60), (90,60,40), (160,110,70)),
        ("boss_chief", (180,80,45), (110,50,30), (210,150,110)),
        ("boss_iron_general", (110,120,135), (70,75,85), (140,150,165)),
    ]:
        boss_polished(n, {"boss_mamut":150,"boss_chief":170,"boss_iron_general":190}[n], col, out, acc)
    base_polished()
    projectile_polished()
    for n, col in [("archer",(70,130,180)),("heavy",(120,120,130)),("crossbow",(160,120,80))]:
        unit_polished(n, col)
    print("polished done")
