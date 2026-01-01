import os
import json
from PIL import Image
import numpy as np

# Config
BASE_DIR = "Resources/Assets.xcassets/AppIcon.brandassets"
SOURCE_DIR = "nanobanana-output"

# Source Files
SRC_BACK = "classic_smpte_color_bars_televis.png"
# New Integrated Top Shelf
SRC_TOPSHELF = "cinematic_wide_banner_with_class.png"

def create_blank_image(size):
    return Image.new("RGBA", size, (0, 0, 0, 0))

def process_and_install(src_name, target_dir, filename_1x, filename_2x, size_1x, mode="normal"):
    """
    mode: 'normal', 'blank'
    """
    try:
        # Calculate 2x size
        size_2x = (size_1x[0] * 2, size_1x[1] * 2)

        if mode == "blank":
            print(f"Generating BLANK image for {target_dir}...")
            img_1x = create_blank_image(size_1x)
            img_2x = create_blank_image(size_2x)
        else:
            src_path = os.path.join(SOURCE_DIR, src_name)
            if not os.path.exists(src_path):
                print(f"Source not found: {src_path}")
                return

            img = Image.open(src_path)
            
            # Helper to resize and crop (FULL BLEED)
            def resize_crop(image, target_size):
                img_ratio = image.width / image.height
                target_ratio = target_size[0] / target_size[1]
                
                # To fill the target fully (Full Bleed):
                if img_ratio > target_ratio:
                    # Source is wider: match height, crop width
                    new_height = target_size[1]
                    new_width = int(new_height * img_ratio)
                else:
                    # Source is taller: match width, crop height
                    new_width = target_size[0]
                    new_height = int(new_width / img_ratio)
                    
                resized = image.resize((new_width, new_height), Image.LANCZOS)
                
                left = (new_width - target_size[0]) / 2
                top = (new_height - target_size[1]) / 2
                right = (new_width + target_size[0]) / 2
                bottom = (new_height + target_size[1]) / 2
                
                return resized.crop((left, top, right, bottom))

            img_1x = resize_crop(img, size_1x)
            img_2x = resize_crop(img, size_2x)

        # Save
        full_path_1x = os.path.join(BASE_DIR, target_dir, filename_1x)
        img_1x.save(full_path_1x)
        print(f"Installed: {full_path_1x}")
        
        full_path_2x = os.path.join(BASE_DIR, target_dir, filename_2x)
        img_2x.save(full_path_2x)
        print(f"Installed: {full_path_2x}")
        
        # Update Contents.json
        json_path = os.path.join(BASE_DIR, target_dir, "Contents.json")
        with open(json_path, 'r') as f:
            data = json.load(f)
            
        updated = False
        for item in data['images']:
            if item['scale'] == '1x':
                item['filename'] = filename_1x
                updated = True
            elif item['scale'] == '2x':
                item['filename'] = filename_2x
                updated = True
                
        if updated:
            with open(json_path, 'w') as f:
                json.dump(data, f, indent=2)
            print(f"Updated JSON: {json_path}")

    except Exception as e:
        print(f"Error processing {target_dir}: {e}")

def main():
    # --- SMALL ICON (400x240) ---
    process_and_install(SRC_BACK, "App Icon - Small.imagestack/Back.imagestacklayer/Content.imageset", 
                       "MD-Icon.png", "MD-Icon@2x.png", (400, 240), mode="normal")
    process_and_install(None, "App Icon - Small.imagestack/Middle.imagestacklayer/Content.imageset", 
                       "MD-Icon.png", "MD-Icon@2x.png", (400, 240), mode="blank")
    process_and_install(None, "App Icon - Small.imagestack/Front.imagestacklayer/Content.imageset", 
                       "MD-Icon.png", "MD-Icon@2x.png", (400, 240), mode="blank")
                       
    # --- LARGE ICON (1280x768) ---
    process_and_install(SRC_BACK, "App Icon - Large.imagestack/Back.imagestacklayer/Content.imageset", 
                       "MD-Icon-Large.png", "MD-Icon-Large@2x.png", (1280, 768), mode="normal")
    process_and_install(None, "App Icon - Large.imagestack/Middle.imagestacklayer/Content.imageset", 
                       "MD-Icon-Large.png", "MD-Icon-Large@2x.png", (1280, 768), mode="blank")
    process_and_install(None, "App Icon - Large.imagestack/Front.imagestacklayer/Content.imageset", 
                       "MD-Icon-Large.png", "MD-Icon-Large@2x.png", (1280, 768), mode="blank")

    # --- TOP SHELF ---
    # Standard (1920x720)
    process_and_install(SRC_TOPSHELF, "Top Shelf Image.imageset", 
                       "Top_Shelf_TopShelf_1920x720.png", "Top_Shelf_TopShelf_3840x1440.png", (1920, 720), mode="normal")
                       
    # Wide (2320x720)
    process_and_install(SRC_TOPSHELF, "Top Shelf Image Wide.imageset", 
                       "Top_Shelf_TopShelfWide_2320x720.png", "Top_Shelf_TopShelfWide_4640x1440.png", (2320, 720), mode="normal")

if __name__ == "__main__":
    main()
