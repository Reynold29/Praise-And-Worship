import os
import subprocess

base_dir = "/Users/reyzie29/Documents/Personal Projects/Praise-And-Worship/app designs"
artifact_dir = "/Users/reyzie29/.gemini/antigravity-ide/brain/04d35cd7-a681-40a1-9d4b-726634c421f7"

os.makedirs(f"{base_dir}/logo", exist_ok=True)
os.makedirs(f"{base_dir}/android/adaptive_layers", exist_ok=True)
os.makedirs(f"{base_dir}/android/preview_shapes", exist_ok=True)
os.makedirs(f"{base_dir}/ios/preview", exist_ok=True)

# ==============================================================================
# 1. LOGO (With enlarged text "WORSHIP COMPANION", no bolt, balanced cross)
# ==============================================================================
logo_dark_svg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 850" width="800" height="850">
  <defs>
    <radialGradient id="bgGrad" cx="50%" cy="30%" r="75%">
      <stop offset="0%" stop-color="#0b1e38"/>
      <stop offset="55%" stop-color="#061224"/>
      <stop offset="100%" stop-color="#02060e"/>
    </radialGradient>
    <radialGradient id="auroraGlow" cx="50%" cy="38%" r="55%">
      <stop offset="0%" stop-color="#64ffda" stop-opacity="0.45"/>
      <stop offset="35%" stop-color="#00b4d8" stop-opacity="0.25"/>
      <stop offset="70%" stop-color="#023e8a" stop-opacity="0.1"/>
      <stop offset="100%" stop-color="#000000" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="auroraRing" x1="0%" y1="100%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#0077b6"/>
      <stop offset="35%" stop-color="#00b4d8"/>
      <stop offset="70%" stop-color="#64ffda"/>
      <stop offset="100%" stop-color="#bbf7d0"/>
    </linearGradient>
    <linearGradient id="crossGrad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#ffffff"/>
      <stop offset="25%" stop-color="#bbf7d0"/>
      <stop offset="60%" stop-color="#00b4d8"/>
      <stop offset="100%" stop-color="#032559"/>
    </linearGradient>
    <linearGradient id="textGrad" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#ffffff"/>
      <stop offset="60%" stop-color="#e2fcf4"/>
      <stop offset="100%" stop-color="#bbf7d0"/>
    </linearGradient>
    <filter id="softGlow" x="-25%" y="-25%" width="150%" height="150%">
      <feGaussianBlur stdDeviation="8" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
    <clipPath id="circleClip">
      <circle cx="400" cy="300" r="148"/>
    </clipPath>
  </defs>

  <!-- Background App Card Container -->
  <rect x="20" y="20" width="760" height="810" rx="120" fill="url(#bgGrad)" stroke="#132b4f" stroke-width="2"/>

  <!-- Aurora Glow Aura Behind Cross -->
  <circle cx="400" cy="200" r="150" fill="url(#auroraGlow)"/>

  <!-- Harmonic Sound Wave Rings around emblem -->
  <circle cx="400" cy="300" r="172" fill="none" stroke="#64ffda" stroke-opacity="0.22" stroke-width="2" stroke-dasharray="6 8"/>
  <circle cx="400" cy="300" r="198" fill="none" stroke="#00b4d8" stroke-opacity="0.14" stroke-width="1.5" stroke-dasharray="14 10"/>
  <circle cx="400" cy="300" r="224" fill="none" stroke="#64ffda" stroke-opacity="0.06" stroke-width="1"/>

  <!-- Main Outer Ring -->
  <circle cx="400" cy="300" r="150" fill="#081427" fill-opacity="0.9" stroke="url(#auroraRing)" stroke-width="6" filter="url(#softGlow)"/>

  <!-- Piano Keyboard Inside Circle -->
  <g clip-path="url(#circleClip)">
    <!-- White Keys Background -->
    <rect x="230" y="300" width="340" height="160" fill="#f0fdf4"/>
    
    <!-- Key Dividers -->
    <line x1="280" y1="300" x2="280" y2="450" stroke="#081427" stroke-width="3"/>
    <line x1="320" y1="300" x2="320" y2="450" stroke="#081427" stroke-width="3"/>
    <line x1="360" y1="300" x2="360" y2="450" stroke="#081427" stroke-width="3"/>
    <line x1="440" y1="300" x2="440" y2="450" stroke="#081427" stroke-width="3"/>
    <line x1="480" y1="300" x2="480" y2="450" stroke="#081427" stroke-width="3"/>
    <line x1="520" y1="300" x2="520" y2="450" stroke="#081427" stroke-width="3"/>

    <!-- Black Keys (Left & Right) -->
    <rect x="268" y="300" width="24" height="75" rx="4" fill="#060e1d"/>
    <rect x="308" y="300" width="24" height="75" rx="4" fill="#060e1d"/>
    <rect x="428" y="300" width="24" height="75" rx="4" fill="#060e1d"/>
    <rect x="468" y="300" width="24" height="75" rx="4" fill="#060e1d"/>
    <rect x="508" y="300" width="24" height="75" rx="4" fill="#060e1d"/>
  </g>

  <!-- Horizontal Shelf -->
  <line x1="250" y1="300" x2="550" y2="300" stroke="url(#auroraRing)" stroke-width="4.5" stroke-linecap="round"/>

  <!-- Balanced Cross (Center Key transitions organically into Cross, stops flush with black keys at Y=375) -->
  <!-- Vertical Stem: Y from 105 down to 375 (Flush with adjacent black keys!) -->
  <rect x="382" y="105" width="36" height="270" rx="6" fill="url(#crossGrad)" filter="url(#softGlow)"/>
  <!-- Horizontal Crossbar: Clean, seamless intersection (NO bolt / NO center dot) -->
  <rect x="325" y="170" width="150" height="34" rx="6" fill="url(#crossGrad)" filter="url(#softGlow)"/>

  <!-- Prominent, Larger Typography -->
  <text x="400" y="580" text-anchor="middle" font-family="-apple-system, BlinkMacSystemFont, 'Plus Jakarta Sans', 'Inter', sans-serif" font-size="52" font-weight="800" letter-spacing="11" fill="url(#textGrad)">WORSHIP</text>
  <text x="400" y="640" text-anchor="middle" font-family="-apple-system, BlinkMacSystemFont, 'Plus Jakarta Sans', 'Inter', sans-serif" font-size="32" font-weight="600" letter-spacing="18" fill="#64ffda">COMPANION</text>

  <!-- Aesthetic Soundwave Accent -->
  <path d="M 320 690 Q 360 676 400 690 T 480 690" fill="none" stroke="url(#auroraRing)" stroke-width="3" stroke-linecap="round"/>
</svg>'''

logo_transparent_svg = logo_dark_svg.replace(
  '<rect x="20" y="20" width="760" height="810" rx="120" fill="url(#bgGrad)" stroke="#132b4f" stroke-width="2"/>',
  '<!-- Transparent background -->'
)

# ==============================================================================
# 2. ANDROID ADAPTIVE LAYERS (108dp standard on 1024x1024 canvas, 66% safe zone)
# ==============================================================================
# Background Layer: Full bleed 1024x1024
android_bg_svg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <radialGradient id="bgGrad" cx="50%" cy="40%" r="75%">
      <stop offset="0%" stop-color="#0b1e38"/>
      <stop offset="45%" stop-color="#061224"/>
      <stop offset="85%" stop-color="#030814"/>
      <stop offset="100%" stop-color="#01040a"/>
    </radialGradient>
    <radialGradient id="auroraCenter" cx="50%" cy="45%" r="55%">
      <stop offset="0%" stop-color="#64ffda" stop-opacity="0.30"/>
      <stop offset="40%" stop-color="#00b4d8" stop-opacity="0.15"/>
      <stop offset="80%" stop-color="#000000" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <rect width="1024" height="1024" fill="url(#bgGrad)"/>
  <circle cx="512" cy="460" r="450" fill="url(#auroraCenter)"/>
</svg>'''

# Foreground Layer: STRICT 66% SAFE ZONE (diameter 675px, radius 337.5px from center 512, 512)
# The entire emblem and acoustic rings are sized to fit comfortably inside radius 300px
android_fg_svg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <radialGradient id="auroraGlowFg" cx="50%" cy="40%" r="50%">
      <stop offset="0%" stop-color="#64ffda" stop-opacity="0.5"/>
      <stop offset="35%" stop-color="#00b4d8" stop-opacity="0.25"/>
      <stop offset="100%" stop-color="#000000" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="auroraRingFg" x1="0%" y1="100%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#0077b6"/>
      <stop offset="35%" stop-color="#00b4d8"/>
      <stop offset="70%" stop-color="#64ffda"/>
      <stop offset="100%" stop-color="#bbf7d0"/>
    </linearGradient>
    <linearGradient id="crossGradFg" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#ffffff"/>
      <stop offset="25%" stop-color="#bbf7d0"/>
      <stop offset="60%" stop-color="#00b4d8"/>
      <stop offset="100%" stop-color="#032559"/>
    </linearGradient>
    <filter id="softGlowFg" x="-25%" y="-25%" width="150%" height="150%">
      <feGaussianBlur stdDeviation="9" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
    <clipPath id="circleClipFg">
      <circle cx="512" cy="512" r="215"/>
    </clipPath>
  </defs>

  <!-- Ambient Aurora Halo -->
  <circle cx="512" cy="400" r="230" fill="url(#auroraGlowFg)"/>

  <!-- Harmonic Sound Wave Rings (Outer boundary ~285px radius, strictly inside 337px safe zone) -->
  <circle cx="512" cy="512" r="250" fill="none" stroke="#64ffda" stroke-opacity="0.24" stroke-width="2.5" stroke-dasharray="8 10"/>
  <circle cx="512" cy="512" r="280" fill="none" stroke="#00b4d8" stroke-opacity="0.16" stroke-width="2" stroke-dasharray="16 12"/>

  <!-- Main Circle Outer Ring -->
  <circle cx="512" cy="512" r="215" fill="#081427" fill-opacity="0.9" stroke="url(#auroraRingFg)" stroke-width="8" filter="url(#softGlowFg)"/>

  <!-- Piano Keyboard inside circle -->
  <g clip-path="url(#circleClipFg)">
    <!-- White Keys Background -->
    <rect x="270" y="512" width="484" height="230" fill="#f0fdf4"/>
    
    <!-- Key Dividers -->
    <line x1="337" y1="512" x2="337" y2="730" stroke="#081427" stroke-width="4"/>
    <line x1="395" y1="512" x2="395" y2="730" stroke="#081427" stroke-width="4"/>
    <line x1="453" y1="512" x2="453" y2="730" stroke="#081427" stroke-width="4"/>
    <line x1="571" y1="512" x2="571" y2="730" stroke="#081427" stroke-width="4"/>
    <line x1="629" y1="512" x2="629" y2="730" stroke="#081427" stroke-width="4"/>
    <line x1="687" y1="512" x2="687" y2="730" stroke="#081427" stroke-width="4"/>

    <!-- Black Keys -->
    <rect x="320" y="512" width="34" height="110" rx="5" fill="#060e1d"/>
    <rect x="378" y="512" width="34" height="110" rx="5" fill="#060e1d"/>
    <rect x="554" y="512" width="34" height="110" rx="5" fill="#060e1d"/>
    <rect x="612" y="512" width="34" height="110" rx="5" fill="#060e1d"/>
    <rect x="670" y="512" width="34" height="110" rx="5" fill="#060e1d"/>
  </g>

  <!-- Horizontal Shelf -->
  <line x1="300" y1="512" x2="724" y2="512" stroke="url(#auroraRingFg)" stroke-width="6" stroke-linecap="round"/>

  <!-- Balanced Cross (Center Key transitions seamlessly up into Cross, flush with black keys at Y=622) -->
  <!-- Vertical Stem: Y from 240 to 622 (Height 382, Width 50) -->
  <rect x="487" y="240" width="50" height="382" rx="9" fill="url(#crossGradFg)" filter="url(#softGlowFg)"/>
  <!-- Horizontal Crossbar: X: 407 to 617 (Width 210, Height 48, Y 330) -->
  <rect x="407" y="330" width="210" height="48" rx="9" fill="url(#crossGradFg)" filter="url(#softGlowFg)"/>
</svg>'''

# Monochrome Layer: Android 13+ Material You Themed Icon (Flat pure white silhouette for system tinting)
android_mono_svg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <clipPath id="circleClipMono">
      <circle cx="512" cy="512" r="215"/>
    </clipPath>
  </defs>

  <!-- Main Ring Outline -->
  <circle cx="512" cy="512" r="215" fill="none" stroke="#ffffff" stroke-width="10"/>

  <!-- Soundwave accents -->
  <circle cx="512" cy="512" r="250" fill="none" stroke="#ffffff" stroke-opacity="0.4" stroke-width="3" stroke-dasharray="8 10"/>

  <!-- Piano Keys inside circle -->
  <g clip-path="url(#circleClipMono)">
    <!-- White Keys Base -->
    <rect x="270" y="512" width="484" height="230" fill="#ffffff" fill-opacity="0.35"/>
    <!-- Key Dividers -->
    <line x1="337" y1="512" x2="337" y2="730" stroke="#000000" stroke-width="4"/>
    <line x1="395" y1="512" x2="395" y2="730" stroke="#000000" stroke-width="4"/>
    <line x1="453" y1="512" x2="453" y2="730" stroke="#000000" stroke-width="4"/>
    <line x1="571" y1="512" x2="571" y2="730" stroke="#000000" stroke-width="4"/>
    <line x1="629" y1="512" x2="629" y2="730" stroke="#000000" stroke-width="4"/>
    <line x1="687" y1="512" x2="687" y2="730" stroke="#000000" stroke-width="4"/>

    <!-- Black Keys -->
    <rect x="320" y="512" width="34" height="110" rx="4" fill="#000000"/>
    <rect x="378" y="512" width="34" height="110" rx="4" fill="#000000"/>
    <rect x="554" y="512" width="34" height="110" rx="4" fill="#000000"/>
    <rect x="612" y="512" width="34" height="110" rx="4" fill="#000000"/>
    <rect x="670" y="512" width="34" height="110" rx="4" fill="#000000"/>
  </g>

  <!-- Horizontal Shelf -->
  <line x1="300" y1="512" x2="724" y2="512" stroke="#ffffff" stroke-width="6" stroke-linecap="round"/>

  <!-- Cross Solid White Silhouette -->
  <rect x="487" y="240" width="50" height="382" rx="8" fill="#ffffff"/>
  <rect x="407" y="330" width="210" height="48" rx="8" fill="#ffffff"/>
</svg>'''

# ==============================================================================
# 3. ANDROID UI PREVIEWS (Pixel UI Circle, Samsung One UI Squircle, Themed Icon)
# ==============================================================================
# Pixel UI Circle Preview:
pixel_preview_svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <clipPath id="pixelCircleClip">
      <circle cx="512" cy="512" r="340"/>
    </clipPath>
  </defs>
  <!-- Background Canvas (Simulated home screen dark glass) -->
  <rect width="1024" height="1024" rx="200" fill="#121418"/>
  <g clip-path="url(#pixelCircleClip)">
    {android_bg_svg[android_bg_svg.find("<defs>"):android_bg_svg.rfind("</svg>")]}
    {android_fg_svg[android_fg_svg.find("<defs>"):android_fg_svg.rfind("</svg>")]}
  </g>
  <!-- Circle Stroke Rim for Elevation -->
  <circle cx="512" cy="512" r="340" fill="none" stroke="#ffffff" stroke-opacity="0.1" stroke-width="2"/>
  <text x="512" y="930" text-anchor="middle" font-family="-apple-system, sans-serif" font-size="34" font-weight="600" fill="#e0e2ec">Google Pixel UI (Circle Mask)</text>
</svg>'''

# Samsung One UI Squircle Preview:
samsung_preview_svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <clipPath id="samsungSquircleClip">
      <rect x="172" y="172" width="680" height="680" rx="220"/>
    </clipPath>
  </defs>
  <rect width="1024" height="1024" rx="200" fill="#121418"/>
  <g clip-path="url(#samsungSquircleClip)">
    {android_bg_svg[android_bg_svg.find("<defs>"):android_bg_svg.rfind("</svg>")]}
    {android_fg_svg[android_fg_svg.find("<defs>"):android_fg_svg.rfind("</svg>")]}
  </g>
  <rect x="172" y="172" width="680" height="680" rx="220" fill="none" stroke="#ffffff" stroke-opacity="0.12" stroke-width="2"/>
  <text x="512" y="930" text-anchor="middle" font-family="-apple-system, sans-serif" font-size="34" font-weight="600" fill="#e0e2ec">Samsung One UI (Squircle Mask)</text>
</svg>'''

# Material You Themed Icon Preview (Expressive dynamic color adaptation)
material_you_preview_svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <clipPath id="myClip">
      <circle cx="512" cy="512" r="340"/>
    </clipPath>
  </defs>
  <rect width="1024" height="1024" rx="200" fill="#121418"/>
  <g clip-path="url(#myClip)">
    <!-- Material You Tinted Background (e.g. Sage / Teal dynamic wallpaper tone) -->
    <rect width="1024" height="1024" fill="#1b4d3e"/>
    <!-- Material You Tinted Foreground Emblem (Primary container tonal accent #a7f3d0) -->
    <g fill="#a7f3d0" stroke="#a7f3d0">
      {android_mono_svg.replace('#ffffff', '#a7f3d0')[android_mono_svg.find("<defs>"):android_mono_svg.rfind("</svg>")]}
    </g>
  </g>
  <circle cx="512" cy="512" r="340" fill="none" stroke="#a7f3d0" stroke-opacity="0.2" stroke-width="2"/>
  <text x="512" y="930" text-anchor="middle" font-family="-apple-system, sans-serif" font-size="34" font-weight="600" fill="#a7f3d0">Android 13/14+ Material You (Dynamic Themed)</text>
</svg>'''

# ==============================================================================
# 4. iOS STANDARDS (1024x1024 Full Bleed, Apple Frosted Glass / Specular Sheen)
# ==============================================================================
ios_icon_svg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <!-- Deep Cosmic Obsidian / Teal Gradient -->
    <radialGradient id="iosBg" cx="50%" cy="30%" r="78%">
      <stop offset="0%" stop-color="#0e2343"/>
      <stop offset="45%" stop-color="#08152a"/>
      <stop offset="85%" stop-color="#030814"/>
      <stop offset="100%" stop-color="#010309"/>
    </radialGradient>
    <radialGradient id="iosCrossAura" cx="50%" cy="38%" r="55%">
      <stop offset="0%" stop-color="#64ffda" stop-opacity="0.55"/>
      <stop offset="35%" stop-color="#00b4d8" stop-opacity="0.30"/>
      <stop offset="70%" stop-color="#023e8a" stop-opacity="0.12"/>
      <stop offset="100%" stop-color="#000000" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="iosRingGrad" x1="0%" y1="100%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#0077b6"/>
      <stop offset="35%" stop-color="#00b4d8"/>
      <stop offset="70%" stop-color="#64ffda"/>
      <stop offset="100%" stop-color="#bbf7d0"/>
    </linearGradient>
    <linearGradient id="iosCrossGrad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#ffffff"/>
      <stop offset="25%" stop-color="#bbf7d0"/>
      <stop offset="60%" stop-color="#00b4d8"/>
      <stop offset="100%" stop-color="#042250"/>
    </linearGradient>
    <!-- Apple Liquid Glass Specular Highlight -->
    <linearGradient id="iosGlassHighlight" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#ffffff" stop-opacity="0.22"/>
      <stop offset="40%" stop-color="#ffffff" stop-opacity="0.05"/>
      <stop offset="100%" stop-color="#ffffff" stop-opacity="0"/>
    </linearGradient>
    <filter id="iosGlow" x="-30%" y="-30%" width="160%" height="160%">
      <feGaussianBlur stdDeviation="12" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
    <clipPath id="iosCircleClip">
      <circle cx="512" cy="512" r="310"/>
    </clipPath>
  </defs>

  <!-- iOS Master Full-Bleed 1024x1024 Canvas (System applies 22.37% squircle mask) -->
  <rect width="1024" height="1024" fill="url(#iosBg)"/>

  <!-- Apple Liquid Glass Diagonal Frosted Sheen -->
  <path d="M 0 0 L 1024 0 L 1024 450 L 0 780 Z" fill="url(#iosGlassHighlight)"/>

  <!-- Halo Aura Behind Cross -->
  <circle cx="512" cy="380" r="330" fill="url(#iosCrossAura)"/>

  <!-- Resonance Sound Waves -->
  <circle cx="512" cy="512" r="370" fill="none" stroke="#64ffda" stroke-opacity="0.20" stroke-width="3" stroke-dasharray="12 14"/>
  <circle cx="512" cy="512" r="420" fill="none" stroke="#00b4d8" stroke-opacity="0.14" stroke-width="2.5" stroke-dasharray="20 16"/>

  <!-- Main Emblem Circular Bezel -->
  <circle cx="512" cy="512" r="310" fill="#081427" fill-opacity="0.9" stroke="url(#iosRingGrad)" stroke-width="11" filter="url(#iosGlow)"/>

  <!-- Piano Keyboard -->
  <g clip-path="url(#iosCircleClip)">
    <!-- White Keys with Apple subtle gradient -->
    <rect x="190" y="512" width="644" height="330" fill="#f2faf5"/>
    
    <!-- Key Dividers -->
    <line x1="280" y1="512" x2="280" y2="830" stroke="#081427" stroke-width="5"/>
    <line x1="360" y1="512" x2="360" y2="830" stroke="#081427" stroke-width="5"/>
    <line x1="440" y1="512" x2="440" y2="830" stroke="#081427" stroke-width="5"/>
    <line x1="600" y1="512" x2="600" y2="830" stroke="#081427" stroke-width="5"/>
    <line x1="680" y1="512" x2="680" y2="830" stroke="#081427" stroke-width="5"/>
    <line x1="760" y1="512" x2="760" y2="830" stroke="#081427" stroke-width="5"/>

    <!-- Black Piano Keys with Glass Gloss Accent -->
    <rect x="256" y="512" width="48" height="160" rx="6" fill="#060e1d"/>
    <rect x="336" y="512" width="48" height="160" rx="6" fill="#060e1d"/>
    <rect x="576" y="512" width="48" height="160" rx="6" fill="#060e1d"/>
    <rect x="656" y="512" width="48" height="160" rx="6" fill="#060e1d"/>
    <rect x="736" y="512" width="48" height="160" rx="6" fill="#060e1d"/>
  </g>

  <!-- Horizontal Keybed Shelf -->
  <line x1="220" y1="512" x2="804" y2="512" stroke="url(#iosRingGrad)" stroke-width="8" stroke-linecap="round"/>

  <!-- Perfectly Balanced Cross (No bolt, center key aligns flush at Y=672) -->
  <rect x="476" y="150" width="72" height="522" rx="12" fill="url(#iosCrossGrad)" filter="url(#iosGlow)"/>
  <rect x="362" y="275" width="300" height="68" rx="12" fill="url(#iosCrossGrad)" filter="url(#iosGlow)"/>

  <!-- Subtle Specular Glass Highlight on Top Cross Arm -->
  <path d="M 476 150 L 548 150 L 536 210 L 488 210 Z" fill="#ffffff" fill-opacity="0.35"/>
</svg>'''

# iOS Home Screen Squircle Preview (Simulating iOS home screen appearance)
ios_preview_svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <clipPath id="iosSquircleClip">
      <rect x="112" y="60" width="800" height="800" rx="180"/>
    </clipPath>
  </defs>
  <!-- Wallpaper Canvas -->
  <rect width="1024" height="1024" fill="#0b0e14"/>
  <g clip-path="url(#iosSquircleClip)">
    <g transform="translate(112, 60) scale(0.78125)">
      {ios_icon_svg[ios_icon_svg.find("<defs>"):ios_icon_svg.rfind("</svg>")]}
    </g>
  </g>
  <!-- Apple Subsurface Border -->
  <rect x="112" y="60" width="800" height="800" rx="180" fill="none" stroke="#ffffff" stroke-opacity="0.16" stroke-width="2.5"/>
  <text x="512" y="930" text-anchor="middle" font-family="-apple-system, BlinkMacSystemFont, sans-serif" font-size="34" font-weight="600" fill="#f5f5f7">Apple iOS Home Screen (Continuous Squircle)</text>
</svg>'''

# Save all SVGs
files_to_save = [
  (f"{base_dir}/logo/worship_companion_logo_dark.svg", logo_dark_svg),
  (f"{base_dir}/logo/worship_companion_logo_transparent.svg", logo_transparent_svg),
  (f"{base_dir}/android/adaptive_layers/ic_launcher_background.svg", android_bg_svg),
  (f"{base_dir}/android/adaptive_layers/ic_launcher_foreground.svg", android_fg_svg),
  (f"{base_dir}/android/adaptive_layers/ic_launcher_monochrome.svg", android_mono_svg),
  (f"{base_dir}/android/preview_shapes/pixel_ui_circle_preview.svg", pixel_preview_svg),
  (f"{base_dir}/android/preview_shapes/samsung_oneui_squircle_preview.svg", samsung_preview_svg),
  (f"{base_dir}/android/preview_shapes/material_you_themed_preview.svg", material_you_preview_svg),
  (f"{base_dir}/ios/AppIcon-1024.svg", ios_icon_svg),
  (f"{base_dir}/ios/preview/ios_home_screen_preview.svg", ios_preview_svg),
]

for path, content in files_to_save:
  with open(path, "w") as f:
    f.write(content)
  print(f"Written {path}")

# Copy to artifacts for immediate display
artifact_files = [
  ("worship_companion_logo_dark.svg", logo_dark_svg),
  ("pixel_ui_circle_preview.svg", pixel_preview_svg),
  ("samsung_oneui_squircle_preview.svg", samsung_preview_svg),
  ("material_you_themed_preview.svg", material_you_preview_svg),
  ("ios_home_screen_preview.svg", ios_preview_svg),
  ("ios_appicon_1024.svg", ios_icon_svg),
  ("android_foreground_layer.svg", android_fg_svg),
]

for fname, content in artifact_files:
  path = os.path.join(artifact_dir, fname)
  with open(path, "w") as f:
    f.write(content)
  print(f"Artifact {path}")
