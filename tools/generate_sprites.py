from PIL import Image, ImageDraw, ImageFont
import os

ROOT = r"D:\APK\age-loop\assets"

def ensure_dir(p):
    os.makedirs(p, exist_ok=True)

def draw_shadow(draw, bbox, alpha=40):
    draw.ellipse(bbox, fill=(0,0,0,alpha))

def save(img, path):
    ensure_dir(os.path.dirname(path))
    img.save(path, "PNG")
    print(f"saved {path} {img.size}")

def player():
    s=96
    img=Image.new("RGBA",(s,s),(0,0,0,0))
    d=ImageDraw.Draw(img)
    draw_shadow(d,[8,78,88,92])
    # body fur vest
    d.rounded_rectangle([18,32,78,78], radius=14, fill=(101,67,33), outline=(60,40,20), width=3)
    # fur collar
    d.ellipse([24,28,72,52], fill=(210,180,140), outline=(120,90,60), width=2)
    # head
    d.ellipse([28,8,68,44], fill=(255,218,170), outline=(180,140,100), width=2)
    # hair
    d.arc([28,8,68,32], 180, 360, fill=(60,40,20), width=6)
    # eyes
    d.ellipse([36,22,44,30], fill=(255,255,255))
    d.ellipse([52,22,60,30], fill=(255,255,255))
    d.ellipse([38,24,42,28], fill=(40,20,10))
    d.ellipse([54,24,58,28], fill=(40,20,10))
    d.ellipse([39,25,41,27], fill=(255,255,255))
    d.ellipse([55,25,57,27], fill=(255,255,255))
    # nose
    d.ellipse([44,30,52,36], fill=(230,190,150))
    # mouth
    d.arc([40,34,56,40], 20, 160, fill=(120,60,40), width=2)
    # club on top
    d.rounded_rectangle([44,2,52,22], radius=4, fill=(120,90,60), outline=(80,60,40), width=2)
    d.ellipse([38,0,58,14], fill=(180,160,140), outline=(100,80,60), width=2)
    save(img, os.path.join(ROOT,"characters/player.png"))

def enemy_normal():
    s=72
    img=Image.new("RGBA",(s,s),(0,0,0,0))
    d=ImageDraw.Draw(img)
    draw_shadow(d,[6,60,66,68])
    # body
    d.rounded_rectangle([4,4,68,60], radius=10, fill=(200,60,60), outline=(120,30,30), width=3)
    # armor plate
    d.rectangle([12,18,60,42], fill=(180,40,40), outline=(100,20,20), width=1)
    # eyes angry
    d.ellipse([14,16,26,28], fill=(255,230,100))
    d.ellipse([46,16,58,28], fill=(255,230,100))
    d.ellipse([18,20,22,24], fill=(0,0,0))
    d.ellipse([50,20,54,24], fill=(0,0,0))
    # brows
    d.line([(12,14),(28,20)], fill=(80,10,10), width=3)
    d.line([(60,14),(44,20)], fill=(80,10,10), width=3)
    # mouth
    d.rectangle([22,38,50,46], fill=(90,20,20), outline=(50,10,10), width=2)
    d.rectangle([28,40,34,44], fill=(255,255,255))
    d.rectangle([38,40,44,44], fill=(255,255,255))
    save(img, os.path.join(ROOT,"enemies/normal.png"))

def enemy_fast():
    s=56
    img=Image.new("RGBA",(s,s),(0,0,0,0))
    d=ImageDraw.Draw(img)
    draw_shadow(d,[4,44,52,50])
    d.rounded_rectangle([4,4,52,44], radius=10, fill=(240,160,40), outline=(180,110,20), width=2)
    # speed lines
    d.line([(2,18),(10,18)], fill=(255,255,255,180), width=2)
    d.line([(2,24),(12,24)], fill=(255,255,255,180), width=2)
    # eyes
    d.ellipse([10,12,20,22], fill=(255,255,255))
    d.ellipse([32,12,42,22], fill=(255,255,255))
    d.ellipse([14,16,18,20], fill=(0,0,0))
    d.ellipse([36,16,40,20], fill=(0,0,0))
    # grin
    d.arc([16,26,40,36], 10, 170, fill=(80,30,10), width=2)
    save(img, os.path.join(ROOT,"enemies/fast.png"))

def enemy_tank():
    s=96
    img=Image.new("RGBA",(s,s),(0,0,0,0))
    d=ImageDraw.Draw(img)
    draw_shadow(d,[8,80,88,92])
    # big body with armor
    d.rounded_rectangle([6,6,90,80], radius=16, fill=(130,70,180), outline=(80,40,120), width=4)
    # chest plate
    d.rounded_rectangle([18,20,78,62], radius=8, fill=(160,100,200), outline=(90,50,130), width=2)
    d.line([(48,20),(48,62)], fill=(90,50,130), width=2)
    # rivets
    for x,y in [(28,30),(68,30),(28,52),(68,52)]:
        d.ellipse([x-4,y-4,x+4,y+4], fill=(220,200,80), outline=(150,130,40), width=1)
    # eyes small
    d.ellipse([22,12,34,24], fill=(255,255,180))
    d.ellipse([62,12,74,24], fill=(255,255,180))
    d.ellipse([26,16,30,20], fill=(0,0,0))
    d.ellipse([66,16,70,20], fill=(0,0,0))
    save(img, os.path.join(ROOT,"enemies/tank.png"))

def enemy_ranged():
    s=64
    img=Image.new("RGBA",(s,s),(0,0,0,0))
    d=ImageDraw.Draw(img)
    draw_shadow(d,[6,52,58,58])
    d.rounded_rectangle([4,4,60,52], radius=10, fill=(70,150,200), outline=(40,100,150), width=3)
    # hood
    d.ellipse([14,6,50,36], fill=(90,170,220), outline=(40,100,150), width=2)
    # eyes
    d.ellipse([18,18,28,28], fill=(255,255,255))
    d.ellipse([36,18,46,28], fill=(255,255,255))
    d.ellipse([22,22,26,26], fill=(0,0,0))
    d.ellipse([40,22,44,26], fill=(0,0,0))
    # bow
    d.arc([8,28,56,56], 200, 340, fill=(120,80,40), width=3)
    d.line([(32,32),(32,50)], fill=(220,200,160), width=2)
    save(img, os.path.join(ROOT,"enemies/ranged.png"))

def enemy_berserker():
    s=70
    img=Image.new("RGBA",(s,s),(0,0,0,0))
    d=ImageDraw.Draw(img)
    draw_shadow(d,[6,58,64,66])
    d.rounded_rectangle([4,4,66,58], radius=10, fill=(220,40,40), outline=(140,20,20), width=3)
    # war paint
    d.rectangle([8,24,62,30], fill=(0,0,0,100))
    # eyes red
    d.ellipse([14,14,28,28], fill=(255,100,100))
    d.ellipse([42,14,56,28], fill=(255,100,100))
    d.ellipse([18,18,24,24], fill=(0,0,0))
    d.ellipse([46,18,52,24], fill=(0,0,0))
    # fangs
    d.polygon([(22,38),(26,48),(30,38)], fill=(255,255,255), outline=(180,180,180), width=1)
    d.polygon([(40,38),(44,48),(48,38)], fill=(255,255,255), outline=(180,180,180), width=1)
    # scar
    d.line([(12,36),(22,42)], fill=(80,0,0), width=2)
    save(img, os.path.join(ROOT,"enemies/berserker.png"))

def enemy_elite():
    s=80
    img=Image.new("RGBA",(s,s),(0,0,0,0))
    d=ImageDraw.Draw(img)
    draw_shadow(d,[8,66,72,74])
    d.rounded_rectangle([4,4,76,66], radius=12, fill=(220,190,40), outline=(150,120,20), width=3)
    # helmet
    d.rounded_rectangle([10,6,70,32], radius=8, fill=(240,210,80), outline=(150,120,20), width=2)
    d.rectangle([32,2,48,12], fill=(240,210,80), outline=(150,120,20), width=2)
    # plume
    d.ellipse([36,0,44,10], fill=(200,60,60))
    # eyes
    d.ellipse([18,20,30,32], fill=(255,255,255))
    d.ellipse([50,20,62,32], fill=(255,255,255))
    d.ellipse([22,24,26,28], fill=(0,0,0))
    d.ellipse([54,24,58,28], fill=(0,0,0))
    # armor stripe
    d.rectangle([4,36,76,48], fill=(180,150,20))
    save(img, os.path.join(ROOT,"enemies/elite.png"))

def boss_mamut():
    s=150
    img=Image.new("RGBA",(s,s),(0,0,0,0))
    d=ImageDraw.Draw(img)
    draw_shadow(d,[15,128,135,142])
    # body
    d.rounded_rectangle([10,20,140,120], radius=20, fill=(140,95,60), outline=(90,60,40), width=4)
    # head
    d.ellipse([30,10,120,80], fill=(160,110,70), outline=(90,60,40), width=3)
    # tusks
    d.arc([20,40,60,100], 120, 260, fill=(240,230,210), width=8)
    d.arc([90,40,130,100], 280, 60, fill=(240,230,210), width=8)
    # eyes
    d.ellipse([48,32,64,48], fill=(255,200,100))
    d.ellipse([86,32,102,48], fill=(255,200,100))
    d.ellipse([54,38,60,44], fill=(0,0,0))
    d.ellipse([92,38,98,44], fill=(0,0,0))
    # trunk
    d.rounded_rectangle([64,56,86,110], radius=10, fill=(130,85,55), outline=(90,60,40), width=2)
    d.line([(68,80),(82,80)], fill=(90,60,40), width=1)
    d.line([(68,92),(82,92)], fill=(90,60,40), width=1)
    save(img, os.path.join(ROOT,"enemies/boss_mamut.png"))

def boss_chief():
    s=170
    img=Image.new("RGBA",(s,s),(0,0,0,0))
    d=ImageDraw.Draw(img)
    draw_shadow(d,[20,144,150,158])
    d.rounded_rectangle([12,30,158,130], radius=20, fill=(180,80,45), outline=(110,50,30), width=4)
    # headdress feathers
    for i, col in enumerate([(200,60,60),(240,180,40),(60,160,80)]):
        x=50+i*30
        d.ellipse([x-12,6,x+12,36], fill=col, outline=(80,40,20), width=2)
    # face
    d.ellipse([50,40,120,110], fill=(210,150,110), outline=(110,50,30), width=3)
    # war paint
    d.rectangle([50,68,120,76], fill=(200,40,40))
    d.rectangle([50,84,120,88], fill=(40,40,40))
    # eyes
    d.ellipse([62,58,80,74], fill=(255,255,255))
    d.ellipse([90,58,108,74], fill=(255,255,255))
    d.ellipse([68,64,74,70], fill=(0,0,0))
    d.ellipse([96,64,102,70], fill=(0,0,0))
    # necklace
    d.ellipse([70,104,100,124], fill=(240,210,80), outline=(150,120,20), width=2)
    d.ellipse([80,110,90,118], fill=(200,60,60))
    save(img, os.path.join(ROOT,"enemies/boss_chief.png"))

def boss_iron():
    s=190
    img=Image.new("RGBA",(s,s),(0,0,0,0))
    d=ImageDraw.Draw(img)
    draw_shadow(d,[20,164,170,178])
    # armor body
    d.rounded_rectangle([14,30,176,150], radius=22, fill=(110,120,135), outline=(70,75,85), width=4)
    # chest plate
    d.rounded_rectangle([30,50,160,120], radius=12, fill=(140,150,165), outline=(80,85,95), width=2)
    # rivets
    for x in [40,90,140]:
        for y in [60,100]:
            d.ellipse([x-5,y-5,x+5,y+5], fill=(200,200,210), outline=(100,100,110), width=1)
    # helmet
    d.rounded_rectangle([50,12,140,60], radius=14, fill=(90,100,115), outline=(60,65,75), width=3)
    d.rectangle([80,6,110,18], fill=(90,100,115), outline=(60,65,75), width=2)
    # visor slit red
    d.rectangle([60,36,130,44], fill=(200,40,40), outline=(120,20,20), width=1)
    # cape
    d.polygon([(14,40),(4,150),(30,140)], fill=(120,20,30), outline=(80,10,20), width=2)
    save(img, os.path.join(ROOT,"enemies/boss_iron_general.png"))

def base_tex():
    w,h=340,150
    img=Image.new("RGBA",(w,h),(0,0,0,0))
    d=ImageDraw.Draw(img)
    # shadow
    d.ellipse([20,h-20,320,h-6], fill=(0,0,0,50))
    # wall base stones
    d.rounded_rectangle([0,30,w, h], radius=12, fill=(160,165,175), outline=(110,115,125), width=4)
    # stone pattern
    for y in [50,80,110]:
        for x in range(0,w,40):
            d.rectangle([x+4,y, x+36,y+18], fill=(180,185,195), outline=(130,135,145), width=1)
    # battlements
    for i in range(4):
        x=10+i*(w//4)
        d.rectangle([x,8, x+60,30], fill=(140,145,155), outline=(110,115,125), width=2)
        d.rectangle([x+14,0, x+46,12], fill=(160,165,175), outline=(110,115,125), width=2)
    # gate
    d.rounded_rectangle([w//2-34,70,w//2+34,h], radius=8, fill=(60,45,30), outline=(40,30,20), width=3)
    d.rectangle([w//2-24,90,w//2+24,h], fill=(40,30,20))
    d.ellipse([w//2-8,100,w//2+8,116], fill=(80,60,40))
    # flag
    d.rectangle([w-30,8,w-24,40], fill=(80,70,60), width=2)
    d.polygon([(w-24,10),(w-60,18),(w-24,26)], fill=(200,60,40), outline=(140,30,20), width=2)
    save(img, os.path.join(ROOT,"buildings/base.png"))

def projectile_tex():
    s=24
    img=Image.new("RGBA",(s,s),(0,0,0,0))
    d=ImageDraw.Draw(img)
    d.ellipse([2,2,22,22], fill=(100,180,255,220), outline=(255,255,255), width=2)
    d.ellipse([8,8,16,16], fill=(255,255,255))
    save(img, os.path.join(ROOT,"projectiles/projectile.png"))

def unit_archer():
    s=58
    img=Image.new("RGBA",(s,s),(0,0,0,0))
    d=ImageDraw.Draw(img)
    draw_shadow(d,[6,44,52,50])
    d.rounded_rectangle([4,4,54,44], radius=8, fill=(70,130,180), outline=(40,90,130), width=2)
    d.ellipse([14,10,44,30], fill=(255,220,180), outline=(180,140,100), width=1)
    d.ellipse([20,16,28,24], fill=(255,255,255))
    d.ellipse([32,16,40,24], fill=(255,255,255))
    d.ellipse([23,19,25,21], fill=(0,0,0))
    d.ellipse([35,19,37,21], fill=(0,0,0))
    # bow
    d.arc([8,26,46,44], 200, 340, fill=(120,80,40), width=2)
    save(img, os.path.join(ROOT,"units/archer.png"))

def unit_heavy():
    s=58
    img=Image.new("RGBA",(s,s),(0,0,0,0))
    d=ImageDraw.Draw(img)
    draw_shadow(d,[6,44,52,50])
    d.rounded_rectangle([4,4,54,46], radius=8, fill=(120,120,130), outline=(80,80,90), width=2)
    d.rectangle([10,14,44,36], fill=(160,160,170), outline=(80,80,90), width=1)
    d.ellipse([18,16,26,24], fill=(40,40,50))
    d.ellipse([32,16,40,24], fill=(40,40,50))
    # shield
    d.ellipse([12,28,28,48], fill=(180,180,190), outline=(100,100,110), width=2)
    save(img, os.path.join(ROOT,"units/heavy.png"))

def unit_crossbow():
    s=58
    img=Image.new("RGBA",(s,s),(0,0,0,0))
    d=ImageDraw.Draw(img)
    draw_shadow(d,[6,44,52,50])
    d.rounded_rectangle([4,4,54,44], radius=8, fill=(160,120,80), outline=(110,80,50), width=2)
    d.ellipse([14,10,44,30], fill=(255,220,180), outline=(180,140,100), width=1)
    d.rectangle([10,28,44,34], fill=(90,70,40))
    d.ellipse([20,32,26,38], fill=(200,60,40))
    save(img, os.path.join(ROOT,"units/crossbow.png"))

if __name__=="__main__":
    player()
    enemy_normal()
    enemy_fast()
    enemy_tank()
    enemy_ranged()
    enemy_berserker()
    enemy_elite()
    boss_mamut()
    boss_chief()
    boss_iron()
    base_tex()
    projectile_tex()
    unit_archer()
    unit_heavy()
    unit_crossbow()
    print("done")
