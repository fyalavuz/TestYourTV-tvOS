import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops

# --- Configuration ---
EXPORT_DIR = "PRO_DISPLAY_ASSETS"
SUPER_SAMPLE = 4

# Colors
C_BG_DARK = (10, 12, 16, 255)
C_BARS = [
    (200, 200, 200), # Grey
    (200, 200, 0),   # Yellow
    (0, 200, 200),   # Cyan
    (0, 200, 0),     # Green
    (200, 0, 200),   # Magenta
    (200, 0, 0),     # Red
    (0, 0, 200)      # Blue
]

FONTS_PATH = "/System/Library/Fonts/Supplemental/Avenir Next.ttc" 
# Trying Avenir Next for a more modern look than Helvetica. Fallback handled.

def ensure_dir(path):
    if not os.path.exists(path):
        os.makedirs(path)

def get_font(size, weight="Bold"):
    # Trying to get a specific weight index.
    # Usually index 2 or 7 is bold/demi in Avenir.
    # Let's try to load default first to be safe, then specific.
    try:
        return ImageFont.truetype(FONTS_PATH, size * SUPER_SAMPLE, index=7) # Heavy
    except:
        try:
            return ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", size * SUPER_SAMPLE, index=1)
        except:
            return ImageFont.load_default()

def draw_gradient_text(draw, x, y, text, font, c1, c2):
    # Renders text with a vertical gradient
    # 1. Create a mask of the text
    bbox = draw.textbbox((0,0), text, font=font)
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]
    
    mask = Image.new("L", (w, h), 0)
    m_draw = ImageDraw.Draw(mask)
    m_draw.text((-bbox[0], -bbox[1]), text, font=font, fill=255)
    
    # 2. Create the gradient
    grad = Image.new("RGBA", (w, h), c1)
    # Simple vertical interpolation
    for r in range(h):
        ratio = r / h
        r_val = int(c1[0] * (1-ratio) + c2[0] * ratio)
        g_val = int(c1[1] * (1-ratio) + c2[1] * ratio)
        b_val = int(c1[2] * (1-ratio) + c2[2] * ratio)
        ImageDraw.Draw(grad).line((0, r, w, r), fill=(r_val, g_val, b_val, 255))
        
    # 3. Paste gradient using mask onto the target image
    # Note: 'draw' object modifies the image in place, but we need to paste 'grad'
    # We need access to the image object 'draw' belongs to.
    # PIL Draw object doesn't expose image easily.
    # workaround: We return the text image to be pasted
    return grad, mask, (int(x + bbox[0]), int(y + bbox[1]))

def render_layers(w, h):
    ss_w = w * SUPER_SAMPLE
    ss_h = h * SUPER_SAMPLE
    
    # --- LAYER 0: BACK (Cinematic Test Pattern) ---
    l0 = Image.new("RGBA", (ss_w, ss_h), C_BG_DARK)
    d0 = ImageDraw.Draw(l0)
    
    # Blurred Colors in background
    bar_w = ss_w / 7
    for i, col in enumerate(C_BARS):
        d0.rectangle([i*bar_w, 0, (i+1)*bar_w, ss_h], fill=col + (100,)) # Semi-transparent
    
    # Strong Blur for "Bokeh" effect
    l0 = l0.filter(ImageFilter.GaussianBlur(ss_w * 0.05))
    
    # Dark Vignette
    vig = Image.new("RGBA", (ss_w, ss_h), (0,0,0,0))
    dv = ImageDraw.Draw(vig)
    dv.rectangle([0, 0, ss_w, ss_h], fill=(0,0,0,0), outline=(0,0,0,255), width=int(ss_w*0.1))
    vig = vig.filter(ImageFilter.GaussianBlur(ss_w * 0.1))
    l0.paste(vig, (0,0), vig)
    
    # --- LAYER 1: MIDDLE (Premium Text) ---
    l1 = Image.new("RGBA", (ss_w, ss_h), (0,0,0,0))
    d1 = ImageDraw.Draw(l1)
    
    # Font
    f_size = int(ss_h * 0.16) # Larger text
    font = get_font(f_size, "Bold")
    
    # Text: "Test Your"
    txt = "Test Your"
    
    # Shadow
    # Render shadow text
    shadow_offset = 8 * SUPER_SAMPLE
    bbox = d1.textbbox((0,0), txt, font=font)
    tw = bbox[2] - bbox[0]
    tx = (ss_w - tw) / 2
    ty = ss_h * 0.45 - (bbox[3]-bbox[1])/2
    
    d1.text((tx+shadow_offset, ty+shadow_offset), txt, font=font, fill=(0,0,0,180))
    
    # Gradient Text
    # White to Silver gradient
    grad_img, mask, pos = draw_gradient_text(d1, tx, ty, txt, font, (255, 255, 255), (200, 200, 220))
    l1.paste(grad_img, pos, mask)
    
    # "TV" Badge
    # Small box next to text? Or below?
    # Let's put "TV" in a sleek blue box below "Test Your"
    
    font_small = get_font(int(f_size * 0.4), "Bold")
    tv_txt = "TV"
    bbox_tv = d1.textbbox((0,0), tv_txt, font=font_small)
    tv_w = bbox_tv[2] - bbox_tv[0]
    tv_h = bbox_tv[3] - bbox_tv[1]
    
    pad_x = 20 * SUPER_SAMPLE
    pad_y = 10 * SUPER_SAMPLE
    
    box_w = tv_w + pad_x*2
    box_h = tv_h + pad_y*2
    
    box_x = (ss_w - box_w) / 2
    box_y = ty + (bbox[3]-bbox[1]) + 20 * SUPER_SAMPLE
    
    # Draw rounded box
    d1.rounded_rectangle([box_x, box_y, box_x+box_w, box_y+box_h], radius=box_h/3, fill=(0, 122, 255, 255))
    d1.text((box_x + pad_x, box_y + pad_y - (tv_h*0.1)), tv_txt, font=font_small, fill=(255,255,255,255))
    
    # --- LAYER 2: FRONT (Lens Flare / Glass) ---
    l2 = Image.new("RGBA", (ss_w, ss_h), (0,0,0,0))
    d2 = ImageDraw.Draw(l2)
    
    # Subtle diagonal gloss on top
    # Polygon
    poly = [(0, 0), (ss_w, 0), (ss_w, ss_h*0.4), (0, ss_h*0.1)]
    # We need to draw this on a temp image to adjust alpha
    gloss = Image.new("RGBA", (ss_w, ss_h), (0,0,0,0))
    ImageDraw.Draw(gloss).polygon(poly, fill=(255, 255, 255, 20))
    l2 = Image.alpha_composite(l2, gloss)
    
    # Resize
    l0 = l0.resize((w, h), Image.LANCZOS)
    l1 = l1.resize((w, h), Image.LANCZOS)
    l2 = l2.resize((w, h), Image.LANCZOS)
    
    return l0, l1, l2

def main():
    print("Generating Cinematic Typography Assets...")
    ensure_dir(EXPORT_DIR)
    
    # Small Icon
    for s in [1, 2]:
        w, h = 400*s, 240*s
        l0, l1, l2 = render_layers(w, h)
        l0.save(f"{EXPORT_DIR}/Small_0_Back{'@2x' if s==2 else ''}.png")
        l1.save(f"{EXPORT_DIR}/Small_1_Text{'@2x' if s==2 else ''}.png")
        l2.save(f"{EXPORT_DIR}/Small_2_Logo{'@2x' if s==2 else ''}.png")

    # Large Icon
    for s in [1, 2]:
        w, h = 1280*s, 768*s
        l0, l1, l2 = render_layers(w, h)
        l0.save(f"{EXPORT_DIR}/Large_0_Back{'@2x' if s==2 else ''}.png")
        l1.save(f"{EXPORT_DIR}/Large_1_Text{'@2x' if s==2 else ''}.png")
        l2.save(f"{EXPORT_DIR}/Large_2_Logo{'@2x' if s==2 else ''}.png")
        
    # Top Shelf (Flattened)
    ts_w, ts_h = 1920, 720
    l0, l1, l2 = render_layers(ts_w, ts_h)
    flat = Image.alpha_composite(l0, l1)
    flat = Image.alpha_composite(flat, l2)
    flat.convert("RGB").save(f"{EXPORT_DIR}/TopShelf.png")
    
    # Launch
    li_w, li_h = 1920, 1080
    l0, l1, l2 = render_layers(li_w, li_h)
    flat = Image.alpha_composite(l0, l1)
    flat = Image.alpha_composite(flat, l2)
    flat.convert("RGB").save(f"{EXPORT_DIR}/LaunchImage.png")

if __name__ == "__main__":
    main()
