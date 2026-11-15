"""Builds the 2880x1800 App Store screenshots from raw captures.
   python3 marketing/compose.py
Raw captures go in marketing/raw/, results land in marketing/screenshots/."""
from PIL import Image, ImageDraw, ImageFilter, ImageFont
import sys

W, H = 2880, 1800

def font(size, weight="Bold"):
    f = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", size)
    try: f.set_variation_by_name(weight)
    except Exception: pass
    return f

def gradient():
    top, bottom = (9, 14, 32), (24, 52, 128)
    img = Image.new("RGB", (W, H))
    px = img.load()
    for y in range(H):
        for x in range(0, W):
            t = (0.65 * y / H) + (0.35 * x / W)
            px[x, y] = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(glow)
    d.ellipse((1500, 150, 2900, 1550), fill=(70, 120, 255, 95))
    glow = glow.filter(ImageFilter.GaussianBlur(220))
    return Image.alpha_composite(img.convert("RGBA"), glow)

def with_shadow(canvas, shot, xy):
    pad = 160
    layer = Image.new("RGBA", (shot.width + 2 * pad, shot.height + 2 * pad), (0, 0, 0, 0))
    alpha = shot.split()[3].point(lambda a: int(a * 0.75))
    shadow = Image.new("RGBA", shot.size, (0, 0, 0, 255))
    shadow.putalpha(alpha)
    layer.paste(shadow, (pad, pad + 40))
    layer = layer.filter(ImageFilter.GaussianBlur(60))
    canvas.alpha_composite(layer, (xy[0] - pad, xy[1] - pad))
    canvas.alpha_composite(shot, xy)

R = 27

def cut(img, box, cut_top=False, cut_bottom=False, fade=60):
    """Trims the wallpaper strip around a captured window and rounds its corners. Where a capture
    stops partway through the window (a scrolled settings page) the edge fades out instead."""
    x0, y0, x1, y1 = box
    ss = 4
    mask = Image.new("L", (img.width * ss, img.height * ss), 0)
    top = (y0 - (R if cut_top else 0)) * ss
    bottom = (y1 + (R if cut_bottom else 0)) * ss
    ImageDraw.Draw(mask).rounded_rectangle((x0 * ss, top, x1 * ss, bottom), radius=R * ss, fill=255)
    mask = mask.resize(img.size, Image.LANCZOS)
    px = mask.load()
    for i in range(fade):
        k = i / fade
        for x in range(img.width):
            if cut_top:
                px[x, y0 + i] = int(px[x, y0 + i] * k)
            if cut_bottom:
                px[x, y1 - 1 - i] = int(px[x, y1 - 1 - i] * k)
    out = img.copy()
    out.putalpha(mask)
    return out.crop(box)

def prepare(raw, scale):
    img = Image.open(raw).convert("RGBA")
    w, h = img.size
    name = raw.split("/")[-1]
    if name == "settings-link.png":
        shot = cut(img, (4, 6, 684, h), cut_bottom=True)
    elif name == "settings-triggers.png":
        shot = cut(img, (0, 0, w, h), cut_top=True, cut_bottom=True)
    elif name == "edit-devices.png":
        shot = cut(img, (4, 4, 684, h - 6))
    elif name == "panel-other.png":
        shot = cut(img, (4, 4, 684, h - 7))
    else:
        shot = cut(img, (4, 2, 684, h - 5))
    scale = min(scale, 1330 / shot.width, 1340 / shot.height)
    shot = shot.resize((int(shot.width * scale), int(shot.height * scale)), Image.LANCZOS)
    return shot.filter(ImageFilter.UnsharpMask(radius=1.2, percent=60, threshold=2))

def text_block(canvas, headline, sub):
    d = ImageDraw.Draw(canvas)
    d.text((204, 150), "PairHop", font=font(64, "Semibold"), fill=(150, 175, 255))
    y = 560
    for line in headline:
        d.text((200, y), line, font=font(122), fill=(255, 255, 255))
        y += 150
    y += 50
    for line in sub:
        d.text((204, y), line, font=font(56, "Regular"), fill=(190, 205, 240))
        y += 84

def card(raw, headline, sub, out, scale=1.9):
    canvas = gradient()
    shot = prepare(raw, scale)
    with_shadow(canvas, shot, (W - shot.width - 190, (H - shot.height) // 2))
    text_block(canvas, headline, sub)
    canvas.convert("RGB").save(out, "PNG")
    print("wrote", out)

def strip_card(raw, headline, sub, out):
    """The menu bar crop, wide, with a ring around the PairHop icon."""
    canvas = gradient()
    strip = Image.open(raw).convert("RGBA")
    scale = 2.7
    strip = strip.resize((int(strip.width * scale), int(strip.height * scale)), Image.LANCZOS)
    mask = Image.new("L", strip.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, strip.width, strip.height), radius=34, fill=255)
    strip.putalpha(mask)
    x, y = (W - strip.width) // 2, 1290
    with_shadow(canvas, strip, (x, y))
    d = ImageDraw.Draw(canvas)
    cx, cy = x + int(181 * scale), y + int(33 * scale)
    d.ellipse((cx - 62, cy - 62, cx + 62, cy + 62), outline=(120, 165, 255), width=9)
    d.line((cx, cy - 64, cx, cy - 120), fill=(120, 165, 255), width=7)
    d.text((cx - 90, cy - 205), "PairHop", font=font(72, "Semibold"), fill=(150, 185, 255))
    text_block(canvas, headline, sub)
    canvas.convert("RGB").save(out, "PNG")
    print("wrote", out)

if __name__ == "__main__":
    R_ = "marketing/raw/"
    O_ = "marketing/screenshots/"
    card(R_ + "panel.png",
         ["Move your keyboard", "between Macs", "in one click."],
         ["No Apple ID sync.", "No re-pairing in System Settings."], O_ + "1-one-click.png")
    card(R_ + "panel-other.png",
         ["Works with", "different", "Apple IDs."],
         ["Work Mac, personal Mac, one keyboard.", "Click Use All Here and it is yours."], O_ + "2-different-apple-ids.png")
    card(R_ + "settings-link.png",
         ["Linked once.", "Reachable", "when it counts."],
         ["Falls back to Bluetooth when a VPN or", "Wi-Fi keeps your two Macs apart."], O_ + "3-linked.png")
    card(R_ + "settings-triggers.png",
         ["Hands over", "by itself."],
         ["Sleep, wake and dropped connections", "are handled. Add your own shortcuts."], O_ + "4-automatic.png")
    card(R_ + "edit-devices.png",
         ["Pick your", "devices once."],
         ["Choose the keyboard, trackpad or mouse", "this Mac shares with your other Mac."], O_ + "5-devices.png")
    strip_card(R_ + "menubar.png",
               ["Lives in", "your menu bar."],
               ["No Dock icon. No windows in the way."], O_ + "6-menu-bar.png")
