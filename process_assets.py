import os
from PIL import Image

# Config
OUTPUT_DIR = "PRO_DISPLAY_ASSETS"
SOURCE_DIR = "nanobanana-output"

# Source Map (I'll update these with actual filenames from the previous step)
SRC_BG = "dark_sleek_geometric_pattern_abs.png"
SRC_LOGO = "modern_abstract_tv_display_logo_.png"
SRC_TOPSHELF = "wide_cinematic_banner_for_prodis.png"
SRC_LAUNCH = "vertical_professional_splash_scr.png"

def ensure_dir(path):
    if not os.path.exists(path):
        os.makedirs(path)

def process_image(src_name, dest_name, size):
    try:
        src_path = os.path.join(SOURCE_DIR, src_name)
        if not os.path.exists(src_path):
            print(f"Source not found: {src_path}")
            return

        img = Image.open(src_path)
        
        # Resize/Crop logic
        # For simplicity, we'll resize to cover and crop center
        img_ratio = img.width / img.height
        target_ratio = size[0] / size[1]
        
        if img_ratio > target_ratio:
            # Image is wider than target
            new_height = size[1]
            new_width = int(new_height * img_ratio)
        else:
            # Image is taller than target
            new_width = size[0]
            new_height = int(new_width / img_ratio)
            
        img = img.resize((new_width, new_height), Image.LANCZOS)
        
        # Center crop
        left = (new_width - size[0]) / 2
        top = (new_height - size[1]) / 2
        right = (new_width + size[0]) / 2
        bottom = (new_height + size[1]) / 2
        
        img = img.crop((left, top, right, bottom))
        
        save_path = os.path.join(OUTPUT_DIR, dest_name)
        img.save(save_path)
        print(f"Saved: {save_path} ({size[0]}x{size[1]})")
        
    except Exception as e:
        print(f"Error processing {dest_name}: {e}")

def main():
    ensure_dir(OUTPUT_DIR)
    
    # 1. Icons (Small & Large, 1x & 2x)
    # Ratios: 400x240 is 5:3. 1280x768 is 5:3.
    
    # Small
    process_image(SRC_BG, "Icon_Small_Back.png", (400, 240))
    process_image(SRC_BG, "Icon_Small_Back@2x.png", (800, 480))
    process_image(SRC_LOGO, "Icon_Small_Front.png", (400, 240))
    process_image(SRC_LOGO, "Icon_Small_Front@2x.png", (800, 480))
    
    # Large
    process_image(SRC_BG, "Icon_Large_Back.png", (1280, 768))
    process_image(SRC_BG, "Icon_Large_Back@2x.png", (2560, 1536))
    process_image(SRC_LOGO, "Icon_Large_Front.png", (1280, 768))
    process_image(SRC_LOGO, "Icon_Large_Front@2x.png", (2560, 1536))
    
    # 2. Top Shelf
    process_image(SRC_TOPSHELF, "TopShelf.png", (1920, 720))
    # Note: Sometimes TopShelf requires @2x too, let's create it just in case or stick to 1x if that's what was asked.
    # The list showed Top_Shelf_TopShelf_1920x720.png in GeneratedAssets but manual assets had TopShelf.png. 
    # We will stick to the Manual_Assets naming convention which seems to be the target.
    
    # 3. Launch Image
    process_image(SRC_LAUNCH, "LaunchImage.png", (1920, 1080))

if __name__ == "__main__":
    main()
