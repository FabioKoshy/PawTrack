from SCons.Script import Import
Import("env")
import os
import shutil
from pathlib import Path

# Get project root directory
project_dir = env.subst("$PROJECT_DIR")
assets_dir = os.path.join(project_dir, "assets")
data_dir = os.path.join(project_dir, "data")

# Create data directory if it doesn't exist
if not os.path.exists(data_dir):
    os.makedirs(data_dir)

# Copy files from assets to data
if os.path.exists(assets_dir):
    print("Copying assets to data directory for SPIFFS upload...")
    for file in os.listdir(assets_dir):
        src_file = os.path.join(assets_dir, file)
        dst_file = os.path.join(data_dir, file)
        if os.path.isfile(src_file):
            shutil.copy2(src_file, dst_file)
            print(f"Copied: {file}")

print("SPIFFS data upload configured")