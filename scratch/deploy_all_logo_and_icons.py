import os
import subprocess
import shutil

root_dir = "/Users/reyzie29/Documents/Personal Projects/Praise-And-Worship"
app_designs_dir = os.path.join(root_dir, "app designs")
artifact_dir = "/Users/reyzie29/.gemini/antigravity-ide/brain/04d35cd7-a681-40a1-9d4b-726634c421f7"

# ==============================================================================
# 1. FINAL CLEAN LOGO (NO wave between words; wave is cleanly placed underneath)
# ==============================================================================
logo_dark_svg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 850 900" width="850" height="900">
  <defs>
    <!-- Card Background Gradient -->
    <radialGradient id="bgGrad" cx="50%" cy="26%" r="75%">
      <stop offset="0%" stop-color="#0c213d"/>
      <stop offset="50%" stop-color="#061326"/>
      <stop offset="85%" stop-color="#030914"/>
      <stop offset="100%" stop-color="#01040a"/>
    </radialGradient>

    <!-- Inner Circle Background -->
    <radialGradient id="innerCircleBg" cx="50%" cy="32%" r="68%">
      <stop offset="0%" stop-color="#122d52"/>
      <stop offset="55%" stop-color="#08172c"/>
      <stop offset="100%" stop-color="#040b17"/>
    </radialGradient>

    <!-- Aurora Center Glow Behind Cross -->
    <radialGradient id="auroraGlow" cx="50%" cy="28%" r="55%">
      <stop offset="0%" stop-color="#64ffda" stop-opacity="0.55"/>
      <stop offset="35%" stop-color="#00b4d8" stop-opacity="0.28"/>
      <stop offset="70%" stop-color="#023e8a" stop-opacity="0.10"/>
      <stop offset="100%" stop-color="#000000" stop-opacity="0"/>
    </radialGradient>

    <!-- Radiant Aurora Ring Gradient -->
    <linearGradient id="auroraRing" x1="0%" y1="100%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#0077b6"/>
      <stop offset="30%" stop-color="#00b4d8"/>
      <stop offset="70%" stop-color="#64ffda"/>
      <stop offset="100%" stop-color="#bbf7d0"/>
    </linearGradient>

    <!-- Cross Gradient (No bolt, seamless transition) -->
    <linearGradient id="crossGrad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#ffffff"/>
      <stop offset="25%" stop-color="#d1fae5"/>
      <stop offset="60%" stop-color="#00b4d8"/>
      <stop offset="100%" stop-color="#04234d"/>
    </linearGradient>

    <!-- Typography Gradient -->
    <linearGradient id="worshipGrad" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#ffffff"/>
      <stop offset="50%" stop-color="#f0fdf4"/>
      <stop offset="100%" stop-color="#cbfbf0"/>
    </linearGradient>

    <!-- Glow Filter -->
    <filter id="auroraFilter" x="-30%" y="-30%" width="160%" height="160%">
      <feGaussianBlur stdDeviation="8" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>

    <!-- Clip Path for Lower Keyboard inside the Circle -->
    <clipPath id="circleClip">
      <circle cx="425" cy="275" r="172"/>
    </clipPath>
  </defs>

  <!-- Background App Card Container -->
  <rect x="20" y="20" width="810" height="860" rx="120" fill="url(#bgGrad)" stroke="#132e54" stroke-width="2"/>

  <!-- Halo Aura Behind Cross Inside Circle -->
  <circle cx="425" cy="225" r="165" fill="url(#auroraGlow)"/>

  <!-- Subtle Concentric Acoustic Resonance Waves (Outside Circle) -->
  <circle cx="425" cy="275" r="202" fill="none" stroke="#64ffda" stroke-opacity="0.18" stroke-width="2" stroke-dasharray="6 8"/>
  <circle cx="425" cy="275" r="230" fill="none" stroke="#00b4d8" stroke-opacity="0.12" stroke-width="1.5" stroke-dasharray="14 10"/>

  <!-- ============================================================ -->
  <!-- MAIN CIRCLE (Comes completely ABOVE the cross & keys)       -->
  <!-- Radius 175, Center (425, 275). Top is at Y=100.              -->
  <!-- ============================================================ -->
  <circle cx="425" cy="275" r="175" fill="url(#innerCircleBg)" stroke="url(#auroraRing)" stroke-width="7" filter="url(#auroraFilter)"/>

  <!-- Piano Keyboard (Lower Half of Circle) -->
  <g clip-path="url(#circleClip)">
    <!-- White Keys Base -->
    <rect x="235" y="275" width="380" height="190" fill="#f0fdf4"/>

    <!-- Key Dividers -->
    <line x1="292" y1="275" x2="292" y2="450" stroke="#081427" stroke-width="3.5"/>
    <line x1="338" y1="275" x2="338" y2="450" stroke="#081427" stroke-width="3.5"/>
    <line x1="384" y1="275" x2="384" y2="450" stroke="#081427" stroke-width="3.5"/>
    <line x1="466" y1="275" x2="466" y2="450" stroke="#081427" stroke-width="3.5"/>
    <line x1="512" y1="275" x2="512" y2="450" stroke="#081427" stroke-width="3.5"/>
    <line x1="558" y1="275" x2="558" y2="450" stroke="#081427" stroke-width="3.5"/>

    <!-- Black Keys (Flush with center key at Y=355) -->
    <rect x="279" y="275" width="26" height="80" rx="4" fill="#060e1d"/>
    <rect x="325" y="275" width="26" height="80" rx="4" fill="#060e1d"/>
    <rect x="453" y="275" width="26" height="80" rx="4" fill="#060e1d"/>
    <rect x="499" y="275" width="26" height="80" rx="4" fill="#060e1d"/>
    <rect x="545" y="275" width="26" height="80" rx="4" fill="#060e1d"/>
  </g>

  <!-- Horizontal Keyboard Shelf Inside Circle -->
  <g clip-path="url(#circleClip)">
    <line x1="240" y1="275" x2="610" y2="275" stroke="url(#auroraRing)" stroke-width="4.5"/>
  </g>

  <!-- Cross (Inside circle, flush with black keys at Y=355, NO bolt) -->
  <rect x="407" y="135" width="36" height="220" rx="7" fill="url(#crossGrad)" filter="url(#auroraFilter)"/>
  <rect x="345" y="185" width="160" height="36" rx="7" fill="url(#crossGrad)" filter="url(#auroraFilter)"/>

  <!-- ============================================================ -->
  <!-- BIG TYPOGRAPHY (WORSHIP & COMPANION DIRECTLY TOGETHER)       -->
  <!-- ============================================================ -->
  <!-- Line 1: WORSHIP (Large 66px, bold, prominent) -->
  <text x="425" y="565" text-anchor="middle" font-family="-apple-system, BlinkMacSystemFont, 'Plus Jakarta Sans', 'Inter', sans-serif" font-size="66" font-weight="900" letter-spacing="14" fill="url(#worshipGrad)">WORSHIP</text>

  <!-- Line 2: COMPANION (Directly below WORSHIP, large 42px, wide-tracked) -->
  <text x="425" y="630" text-anchor="middle" font-family="-apple-system, BlinkMacSystemFont, 'Plus Jakarta Sans', 'Inter', sans-serif" font-size="42" font-weight="700" letter-spacing="22" fill="#64ffda">COMPANION</text>

  <!-- ============================================================ -->
  <!-- DYNAMIC WAVE DESIGN (BENEATH THE FULL TEXT LOCKUP)           -->
  <!-- ============================================================ -->
  <g filter="url(#auroraFilter)">
    <!-- Flanking Soundwave Bars on Left -->
    <line x1="160" y1="695" x2="160" y2="705" stroke="#0077b6" stroke-width="3" stroke-linecap="round"/>
    <line x1="175" y1="688" x2="175" y2="712" stroke="#00b4d8" stroke-width="3.5" stroke-linecap="round"/>
    <line x1="190" y1="676" x2="190" y2="724" stroke="#00b4d8" stroke-width="3.5" stroke-linecap="round"/>
    <line x1="205" y1="684" x2="205" y2="716" stroke="#64ffda" stroke-width="3.5" stroke-linecap="round"/>
    <line x1="220" y1="672" x2="220" y2="728" stroke="#64ffda" stroke-width="4" stroke-linecap="round"/>

    <!-- Central Fluid Harmonic Wave Ribbon -->
    <path d="M 240 700 Q 285 668 330 700 T 425 700 T 520 700 T 610 700" fill="none" stroke="url(#auroraRing)" stroke-width="4.5" stroke-linecap="round"/>

    <!-- Flanking Soundwave Bars on Right -->
    <line x1="630" y1="672" x2="630" y2="728" stroke="#64ffda" stroke-width="4" stroke-linecap="round"/>
    <line x1="645" y1="684" x2="645" y2="716" stroke="#64ffda" stroke-width="3.5" stroke-linecap="round"/>
    <line x1="660" y1="676" x2="660" y2="724" stroke="#00b4d8" stroke-width="3.5" stroke-linecap="round"/>
    <line x1="675" y1="688" x2="675" y2="712" stroke="#00b4d8" stroke-width="3.5" stroke-linecap="round"/>
    <line x1="690" y1="695" x2="690" y2="705" stroke="#0077b6" stroke-width="3" stroke-linecap="round"/>
  </g>
</svg>'''

logo_transparent_svg = logo_dark_svg.replace(
  '<rect x="20" y="20" width="810" height="860" rx="120" fill="url(#bgGrad)" stroke="#132e54" stroke-width="2"/>',
  '<!-- Transparent Background -->'
)

# Write to app designs/logo
with open(f"{app_designs_dir}/logo/worship_companion_logo_dark.svg", "w") as f:
    f.write(logo_dark_svg)

with open(f"{app_designs_dir}/logo/worship_companion_logo_transparent.svg", "w") as f:
    f.write(logo_transparent_svg)

# Rasterize master logos
for fname in ["worship_companion_logo_dark", "worship_companion_logo_transparent"]:
    svg_p = f"{app_designs_dir}/logo/{fname}.svg"
    subprocess.run(["qlmanage", "-t", "-s", "1024", "-o", f"{app_designs_dir}/logo", svg_p], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    src_png = f"{app_designs_dir}/logo/{fname}.svg.png"
    target_png = f"{app_designs_dir}/logo/{fname}.png"
    if os.path.exists(src_png):
        os.replace(src_png, target_png)

print("Master logos rendered in app designs/logo/")

# ==============================================================================
# 2. UPDATE PROJECT LOGO ASSETS
# ==============================================================================
# 2.1 Update assets/icons/app_logo.png (Square App Badge Icon for QR & In-App)
master_icon = f"{app_designs_dir}/ios/AppIcon-1024.png"
app_logo_dest = os.path.join(root_dir, "assets/icons/app_logo.png")
shutil.copyfile(master_icon, app_logo_dest)
print(f"Updated {app_logo_dest}")

# 2.2 Update share-web/app_logo.png (Used in Web sharing pages & web headers)
web_logo_dest = os.path.join(root_dir, "share-web/app_logo.png")
shutil.copyfile(master_icon, web_logo_dest)
print(f"Updated {web_logo_dest}")

# ==============================================================================
# 3. UPDATE ANDROID MIPMAPS & ADAPTIVE ICON XMLs
# ==============================================================================
android_res = os.path.join(root_dir, "android/app/src/main/res")

# Update colors/background fallback
values_dir = os.path.join(android_res, "values")
os.makedirs(values_dir, exist_ok=True)
with open(os.path.join(values_dir, "ic_launcher_background.xml"), "w") as f:
    f.write('''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#081427</color>
</resources>
''')

# Update mipmap-anydpi-v26
anydpi = os.path.join(android_res, "mipmap-anydpi-v26")
os.makedirs(anydpi, exist_ok=True)
adaptive_xml = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />
</adaptive-icon>
'''
with open(os.path.join(anydpi, "ic_launcher.xml"), "w") as f:
    f.write(adaptive_xml)

with open(os.path.join(anydpi, "ic_launcher_round.xml"), "w") as f:
    f.write(adaptive_xml)

# Copy all mipmap directories from app designs/android/res into android/app/src/main/res
designs_res = os.path.join(app_designs_dir, "android/res")
for folder in ["mipmap-mdpi", "mipmap-hdpi", "mipmap-xhdpi", "mipmap-xxhdpi", "mipmap-xxxhdpi"]:
    src_folder = os.path.join(designs_res, folder)
    dst_folder = os.path.join(android_res, folder)
    os.makedirs(dst_folder, exist_ok=True)
    for item in os.listdir(src_folder):
        s_item = os.path.join(src_folder, item)
        d_item = os.path.join(dst_folder, item)
        shutil.copyfile(s_item, d_item)

print("Updated all Android mipmaps in android/app/src/main/res/")

# ==============================================================================
# 4. UPDATE IOS APPICONSET
# ==============================================================================
ios_appiconset_dst = os.path.join(root_dir, "ios/Runner/Assets.xcassets/AppIcon.appiconset")
ios_appiconset_src = os.path.join(app_designs_dir, "ios/AppIcon.appiconset")
if os.path.exists(ios_appiconset_src):
    for item in os.listdir(ios_appiconset_src):
        s_item = os.path.join(ios_appiconset_src, item)
        d_item = os.path.join(ios_appiconset_dst, item)
        shutil.copyfile(s_item, d_item)
    print("Updated all iOS app icons in ios/Runner/Assets.xcassets/AppIcon.appiconset/")

# ==============================================================================
# 5. COPY TO ARTIFACTS FOR PREVIEW
# ==============================================================================
shutil.copyfile(f"{app_designs_dir}/logo/worship_companion_logo_dark.png", f"{artifact_dir}/worship_companion_logo_dark.png")
shutil.copyfile(f"{app_designs_dir}/logo/worship_companion_logo_transparent.png", f"{artifact_dir}/worship_companion_logo_transparent.png")
shutil.copyfile(f"{app_designs_dir}/android/preview_shapes/pixel_ui_circle_preview.png", f"{artifact_dir}/pixel_ui_circle_preview.png")
shutil.copyfile(f"{app_designs_dir}/android/preview_shapes/samsung_oneui_squircle_preview.png", f"{artifact_dir}/samsung_oneui_squircle_preview.png")
shutil.copyfile(f"{app_designs_dir}/android/preview_shapes/material_you_themed_preview.png", f"{artifact_dir}/material_you_themed_preview.png")
shutil.copyfile(f"{app_designs_dir}/ios/preview/ios_home_screen_preview.png", f"{artifact_dir}/ios_home_screen_preview.png")

print("All files deployed and synchronized across all respective places!")
