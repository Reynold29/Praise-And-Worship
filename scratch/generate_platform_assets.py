import os
import subprocess

base_dir = "/Users/reyzie29/Documents/Personal Projects/Praise-And-Worship/app designs"
artifact_dir = "/Users/reyzie29/.gemini/antigravity-ide/brain/04d35cd7-a681-40a1-9d4b-726634c421f7"

# -------------------------------------------------------------
# 1. iOS 18 Dark & Tinted Variants
# -------------------------------------------------------------
ios_dark_svg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <radialGradient id="iosDarkBg" cx="50%" cy="30%" r="75%">
      <stop offset="0%" stop-color="#0a0e17"/>
      <stop offset="60%" stop-color="#04060a"/>
      <stop offset="100%" stop-color="#000000"/>
    </radialGradient>
    <radialGradient id="iosDarkAura" cx="50%" cy="38%" r="55%">
      <stop offset="0%" stop-color="#64ffda" stop-opacity="0.45"/>
      <stop offset="35%" stop-color="#00b4d8" stop-opacity="0.22"/>
      <stop offset="100%" stop-color="#000000" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="iosDarkRing" x1="0%" y1="100%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#0077b6"/>
      <stop offset="35%" stop-color="#00b4d8"/>
      <stop offset="70%" stop-color="#64ffda"/>
      <stop offset="100%" stop-color="#bbf7d0"/>
    </linearGradient>
    <linearGradient id="iosDarkCross" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#ffffff"/>
      <stop offset="25%" stop-color="#bbf7d0"/>
      <stop offset="60%" stop-color="#00b4d8"/>
      <stop offset="100%" stop-color="#031838"/>
    </linearGradient>
    <filter id="iosDarkGlow" x="-30%" y="-30%" width="160%" height="160%">
      <feGaussianBlur stdDeviation="12" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
    <clipPath id="iosDarkCircleClip">
      <circle cx="512" cy="512" r="310"/>
    </clipPath>
  </defs>

  <rect width="1024" height="1024" fill="url(#iosDarkBg)"/>
  <circle cx="512" cy="380" r="330" fill="url(#iosDarkAura)"/>
  <circle cx="512" cy="512" r="370" fill="none" stroke="#64ffda" stroke-opacity="0.16" stroke-width="3" stroke-dasharray="12 14"/>
  <circle cx="512" cy="512" r="420" fill="none" stroke="#00b4d8" stroke-opacity="0.10" stroke-width="2.5" stroke-dasharray="20 16"/>

  <circle cx="512" cy="512" r="310" fill="#040914" stroke="url(#iosDarkRing)" stroke-width="11" filter="url(#iosDarkGlow)"/>

  <g clip-path="url(#iosDarkCircleClip)">
    <rect x="190" y="512" width="644" height="330" fill="#e2edf5"/>
    <line x1="280" y1="512" x2="280" y2="830" stroke="#040914" stroke-width="5"/>
    <line x1="360" y1="512" x2="360" y2="830" stroke="#040914" stroke-width="5"/>
    <line x1="440" y1="512" x2="440" y2="830" stroke="#040914" stroke-width="5"/>
    <line x1="600" y1="512" x2="600" y2="830" stroke="#040914" stroke-width="5"/>
    <line x1="680" y1="512" x2="680" y2="830" stroke="#040914" stroke-width="5"/>
    <line x1="760" y1="512" x2="760" y2="830" stroke="#040914" stroke-width="5"/>

    <rect x="256" y="512" width="48" height="160" rx="6" fill="#02050a"/>
    <rect x="336" y="512" width="48" height="160" rx="6" fill="#02050a"/>
    <rect x="576" y="512" width="48" height="160" rx="6" fill="#02050a"/>
    <rect x="656" y="512" width="48" height="160" rx="6" fill="#02050a"/>
    <rect x="736" y="512" width="48" height="160" rx="6" fill="#02050a"/>
  </g>

  <line x1="220" y1="512" x2="804" y2="512" stroke="url(#iosDarkRing)" stroke-width="8" stroke-linecap="round"/>

  <rect x="476" y="150" width="72" height="522" rx="12" fill="url(#iosDarkCross)" filter="url(#iosDarkGlow)"/>
  <rect x="362" y="275" width="300" height="68" rx="12" fill="url(#iosDarkCross)" filter="url(#iosDarkGlow)"/>
</svg>'''

with open(f"{base_dir}/ios/AppIcon-1024-dark.svg", "w") as f:
    f.write(ios_dark_svg)

subprocess.run(["qlmanage", "-t", "-s", "1024", "-o", f"{base_dir}/ios", f"{base_dir}/ios/AppIcon-1024-dark.svg"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
if os.path.exists(f"{base_dir}/ios/AppIcon-1024-dark.svg.png"):
    os.replace(f"{base_dir}/ios/AppIcon-1024-dark.svg.png", f"{base_dir}/ios/AppIcon-1024-dark.png")

# -------------------------------------------------------------
# 2. Android Adaptive Icon XML Definition (mipmap-anydpi-v26)
# -------------------------------------------------------------
res_dir = f"{base_dir}/android/res"
anydpi_dir = f"{res_dir}/mipmap-anydpi-v26"
os.makedirs(anydpi_dir, exist_ok=True)

ic_launcher_xml = '''<?xml version="1.0" encoding="utf-8"?>
<!-- Android Adaptive Icon Definition (Google Material Standards) -->
<!-- Supports Android 8.0+ Adaptive Icons & Android 13+ Material You Expressive Theming -->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />
</adaptive-icon>
'''
with open(f"{anydpi_dir}/ic_launcher.xml", "w") as f:
    f.write(ic_launcher_xml)

with open(f"{anydpi_dir}/ic_launcher_round.xml", "w") as f:
    f.write(ic_launcher_xml)

# -------------------------------------------------------------
# 3. Generate Android Mipmap Sizes via macOS sips
# -------------------------------------------------------------
densities = {
    "mipmap-mdpi": (48, 108),
    "mipmap-hdpi": (72, 162),
    "mipmap-xhdpi": (96, 216),
    "mipmap-xxhdpi": (144, 324),
    "mipmap-xxxhdpi": (192, 432),
}

bg_src = f"{base_dir}/android/adaptive_layers/ic_launcher_background.png"
fg_src = f"{base_dir}/android/adaptive_layers/ic_launcher_foreground.png"
mono_src = f"{base_dir}/android/adaptive_layers/ic_launcher_monochrome.png"
ios_src = f"{base_dir}/ios/AppIcon-1024.png"

for folder, (launcher_sz, layer_sz) in densities.items():
    d_path = os.path.join(res_dir, folder)
    os.makedirs(d_path, exist_ok=True)
    
    # Adaptive layers
    subprocess.run(["sips", "-z", str(layer_sz), str(layer_sz), bg_src, "--out", os.path.join(d_path, "ic_launcher_background.png")], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    subprocess.run(["sips", "-z", str(layer_sz), str(layer_sz), fg_src, "--out", os.path.join(d_path, "ic_launcher_foreground.png")], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    subprocess.run(["sips", "-z", str(layer_sz), str(layer_sz), mono_src, "--out", os.path.join(d_path, "ic_launcher_monochrome.png")], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    # Legacy launcher icon
    subprocess.run(["sips", "-z", str(launcher_sz), str(launcher_sz), ios_src, "--out", os.path.join(d_path, "ic_launcher.png")], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    subprocess.run(["sips", "-z", str(launcher_sz), str(launcher_sz), ios_src, "--out", os.path.join(d_path, "ic_launcher_round.png")], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

print("Android res mipmaps generated successfully with sips!")
