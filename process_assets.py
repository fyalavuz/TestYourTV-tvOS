import os
from PIL import Image

# Config
OUTPUT_DIR = "PRO_DISPLAY_ASSETS"
SOURCE_DIR = "nanobanana-output"

# Source Files (Updated for Premium Concept)
SRC_BACK = "dark_grey_brushed_aluminum_textu.png"
SRC_MIDDLE = "minimalist_technical_wireframe_g.png"
SRC_FRONT = "glossy_glass_prism_in_the_shape_.png"
SRC_TOPSHELF = "cinematic_wide_shot_of_a_highend.png"
SRC_TOPSHELF_WIDE = "abstract_wide_artistic_banner_fe.png"

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
        
        # 1. Resize (Cover)
        img_ratio = img.width / img.height
        target_ratio = size[0] / size[1]
        
        if img_ratio > target_ratio:
            new_height = size[1]
            new_width = int(new_height * img_ratio)
        else:
            new_width = size[0]
            new_height = int(new_width / img_ratio)
            
        img = img.resize((new_width, new_height), Image.LANCZOS)
        
        # 2. Crop (Center)
        left = (new_width - size[0]) / 2
        top = (new_height - size[1]) / 2
        right = (new_width + size[0]) / 2
        bottom = (new_height + size[1]) / 2
        
        img = img.crop((left, top, right, bottom))
        
        # 3. Save
        save_path = os.path.join(OUTPUT_DIR, dest_name)
        img.save(save_path)
        print(f"Saved: {dest_name} ({size[0]}x{size[1]})")
        
    except Exception as e:
        print(f"Error processing {dest_name}: {e}")

def main():
    ensure_dir(OUTPUT_DIR)
    
    # --- APP ICONS ---
    
    # Back Layer
    process_image(SRC_BACK, "Icon_Small_Back.png", (400, 240))
    process_image(SRC_BACK, "Icon_Small_Back@2x.png", (800, 480))
    process_image(SRC_BACK, "Icon_Large_Back.png", (1280, 768))
    process_image(SRC_BACK, "Icon_Large_Back@2x.png", (2560, 1536))
    
    # Middle Layer
    process_image(SRC_MIDDLE, "Icon_Small_Middle.png", (400, 240))
    process_image(SRC_MIDDLE, "Icon_Small_Middle@2x.png", (800, 480))
    process_image(SRC_MIDDLE, "Icon_Large_Middle.png", (1280, 768))
    process_image(SRC_MIDDLE, "Icon_Large_Middle@2x.png", (2560, 1536))
    
    # Front Layer
    process_image(SRC_FRONT, "Icon_Small_Front.png", (400, 240))
    process_image(SRC_FRONT, "Icon_Small_Front@2x.png", (800, 480))
    process_image(SRC_FRONT, "Icon_Large_Front.png", (1280, 768))
    process_image(SRC_FRONT, "Icon_Large_Front@2x.png", (2560, 1536))
    
    # --- TOP SHELF ---
    
    # Standard
    process_image(SRC_TOPSHELF, "Top_Shelf_TopShelf_1920x720.png", (1920, 720))
    process_image(SRC_TOPSHELF, "Top_Shelf_TopShelf_3840x1440.png", (3840, 1440))
    
    # Wide
    process_image(SRC_TOPSHELF_WIDE, "Top_Shelf_TopShelfWide_2320x720.png", (2320, 720))
    process_image(SRC_TOPSHELF_WIDE, "Top_Shelf_TopShelfWide_4640x1440.png", (4640, 1440))

if __name__ == "__main__":
    main()
