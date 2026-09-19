#!/usr/bin/env python3
"""
Generate correct monochrome stencil PNGs for Android adaptive icon Material You support.
"""
from PIL import Image, ImageFilter
import numpy as np
import os, shutil

project = "/Users/reyzie29/Documents/Personal Projects/Praise-And-Worship"

dpi_dirs = [
    'mipmap-mdpi',
    'mipmap-hdpi',
    'mipmap-xhdpi',
    'mipmap-xxhdpi',
    'mipmap-xxxhdpi',
]

def create_monochrome_stencil(foreground_img):
    fg = foreground_img.convert("RGBA")
    arr = np.array(fg, dtype=np.float32)
    R, G, B, A = arr[:,:,0], arr[:,:,1], arr[:,:,2], arr[:,:,3]
    # Perceptual luminance
    lum = 0.2126 * R + 0.7152 * G + 0.0722 * B
    # Background is very dark (luminance ~3-24), shapes are bright (40+)
    threshold = 35.0
    shape_mask = np.clip((lum - threshold) / (255.0 - threshold), 0.0, 1.0)
    shape_mask = np.power(shape_mask, 0.5)
    shape_mask = np.clip(shape_mask * 2.2, 0.0, 1.0)
    h, w = lum.shape
    out = np.zeros((h, w, 4), dtype=np.uint8)
    out[:,:,0] = 255
    out[:,:,1] = 255
    out[:,:,2] = 255
    out[:,:,3] = (shape_mask * 255).astype(np.uint8)
    return Image.fromarray(out, 'RGBA')

for dpi_dir in dpi_dirs:
    fg_path = os.path.join(project, "android/app/src/main/res", dpi_dir, "ic_launcher_foreground.png")
    mono_path = os.path.join(project, "android/app/src/main/res", dpi_dir, "ic_launcher_monochrome.png")
    if not os.path.exists(fg_path):
        print(f"  Skipping {dpi_dir} - no foreground")
        continue
    fg_img = Image.open(fg_path)
    mono = create_monochrome_stencil(fg_img)
    mono = mono.filter(ImageFilter.SMOOTH)
    if os.path.exists(mono_path):
        shutil.copy2(mono_path, mono_path + ".bak")
    mono.save(mono_path, 'PNG')
    arr = np.array(mono)
    non_t = np.sum(arr[:,:,3] > 0)
    total = arr[:,:,3].size
    print(f"  {dpi_dir}: {mono.size} | visible: {non_t}/{total} ({100*non_t/total:.1f}%)")

print("Done!")
