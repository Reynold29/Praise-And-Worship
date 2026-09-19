import os
import subprocess

root_dir = "/Users/reyzie29/Documents/Personal Projects/Praise-And-Worship"
app_designs_dir = os.path.join(root_dir, "app designs")
android_res = os.path.join(root_dir, "android/app/src/main/res")
artifact_dir = "/Users/reyzie29/.gemini/antigravity-ide/brain/04d35cd7-a681-40a1-9d4b-726634c421f7"

# ==============================================================================
# PERFECT MONOCHROME STENCIL FOR ANDROID 13+ / SAMSUNG ONE UI THEMED ICONS
# Crucial rules for Android monochrome icon:
# 1. Background MUST be 100% transparent (alpha = 0).
# 2. Everything that takes the accent tint MUST be pure white (#ffffff, alpha = 1).
# 3. Negative spaces (black keys, gaps, inner space) MUST be 100% transparent (alpha = 0),
#    NOT black (#000000)! If you use black, Android treats it as opaque and tints it!
# ==============================================================================
mono_stencil_svg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <!-- Mask to cut out black keys and gaps from the white keyboard -->
    <mask id="pianoMask">
      <!-- White reveals -->
      <rect width="1024" height="1024" fill="#ffffff" />
      <!-- Black cuts out (transparent in result) -->
      <!-- Black Keys cut out -->
      <rect x="318" y="512" width="34" height="106" rx="5" fill="#000000" />
      <rect x="378" y="512" width="34" height="106" rx="5" fill="#000000" />
      <rect x="552" y="512" width="34" height="106" rx="5" fill="#000000" />
      <rect x="612" y="512" width="34" height="106" rx="5" fill="#000000" />
      <rect x="672" y="512" width="34" height="106" rx="5" fill="#000000" />
      <!-- Key Dividers cut out -->
      <line x1="335" y1="512" x2="335" y2="745" stroke="#000000" stroke-width="5" />
      <line x1="395" y1="512" x2="395" y2="745" stroke="#000000" stroke-width="5" />
      <line x1="455" y1="512" x2="455" y2="745" stroke="#000000" stroke-width="5" />
      <line x1="569" y1="512" x2="569" y2="745" stroke="#000000" stroke-width="5" />
      <line x1="629" y1="512" x2="629" y2="745" stroke="#000000" stroke-width="5" />
      <line x1="689" y1="512" x2="689" y2="745" stroke="#000000" stroke-width="5" />
      <!-- Shelf line cut out -->
      <line x1="260" y1="512" x2="764" y2="512" stroke="#000000" stroke-width="7" />
    </mask>

    <!-- Clip to circle for piano keys -->
    <clipPath id="circleClipMono">
      <circle cx="512" cy="512" r="226" />
    </clipPath>
  </defs>

  <!-- Entire canvas is transparent by default -->

  <!-- Outer Ring (Pure White #FFFFFF) -->
  <circle cx="512" cy="512" r="230" fill="none" stroke="#ffffff" stroke-width="14" />

  <!-- Acoustic Waves (Pure White with opacity) -->
  <circle cx="512" cy="512" r="268" fill="none" stroke="#ffffff" stroke-opacity="0.5" stroke-width="3.5" stroke-dasharray="8 10" />

  <!-- Piano Keyboard: White keys with black keys CUT OUT via mask -->
  <g clip-path="url(#circleClipMono)">
    <g mask="url(#pianoMask)">
      <rect x="260" y="512" width="504" height="250" fill="#ffffff" fill-opacity="0.85" />
    </g>
  </g>

  <!-- Cross (Solid Pure White #FFFFFF) -->
  <rect x="488" y="328" width="48" height="290" rx="9" fill="#ffffff" />
  <rect x="407" y="394" width="210" height="48" rx="9" fill="#ffffff" />
</svg>'''

# Save the SVG
mono_svg_path = os.path.join(app_designs_dir, "android/adaptive_layers/ic_launcher_monochrome.svg")
with open(mono_svg_path, "w") as f:
    f.write(mono_stencil_svg)

# Rasterize using qlmanage to 1024x1024
subprocess.run(["qlmanage", "-t", "-s", "1024", "-o", os.path.join(app_designs_dir, "android/adaptive_layers"), mono_svg_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
mono_png_src = os.path.join(app_designs_dir, "android/adaptive_layers/ic_launcher_monochrome.svg.png")
mono_png_dst = os.path.join(app_designs_dir, "android/adaptive_layers/ic_launcher_monochrome.png")
if os.path.exists(mono_png_src):
    os.replace(mono_png_src, mono_png_dst)

# Update mipmap densities for ic_launcher_monochrome.png
densities = {
    "mipmap-mdpi": 108,
    "mipmap-hdpi": 162,
    "mipmap-xhdpi": 216,
    "mipmap-xxhdpi": 324,
    "mipmap-xxxhdpi": 432,
}

for folder, layer_sz in densities.items():
    dst_p = os.path.join(android_res, folder, "ic_launcher_monochrome.png")
    subprocess.run(["sips", "-z", str(layer_sz), str(layer_sz), mono_png_dst, "--out", dst_p], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

# Copy to artifacts
shutil_mono_artifact = os.path.join(artifact_dir, "fixed_monochrome_stencil.png")
subprocess.run(["cp", mono_png_dst, shutil_mono_artifact])

print("Fixed monochrome stencil generated across all mipmap folders!")
