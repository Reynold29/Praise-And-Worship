import os
import subprocess

base_dir = "/Users/reyzie29/Documents/Personal Projects/Praise-And-Worship/app designs"
artifact_dir = "/Users/reyzie29/.gemini/antigravity-ide/brain/04d35cd7-a681-40a1-9d4b-726634c421f7"

os.makedirs(f"{base_dir}/logo", exist_ok=True)
os.makedirs(f"{base_dir}/android/adaptive_layers", exist_ok=True)
os.makedirs(f"{base_dir}/android/preview_shapes", exist_ok=True)
os.makedirs(f"{base_dir}/android/res/mipmap-anydpi-v26", exist_ok=True)
os.makedirs(f"{base_dir}/ios/preview", exist_ok=True)
os.makedirs(f"{base_dir}/ios/AppIcon.appiconset", exist_ok=True)

# ==============================================================================
# 1. BRAND LOGO (Self-contained Circle: Cross & Keys INSIDE, Big Text + Wave)
# ==============================================================================
logo_dark_svg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 850 950" width="850" height="950">
  <defs>
    <!-- Card Background Gradient -->
    <radialGradient id="bgGrad" cx="50%" cy="26%" r="75%">
      <stop offset="0%" stop-color="#0c213d"/>
      <stop offset="50%" stop-color="#061326"/>
      <stop offset="85%" stop-color="#030914"/>
      <stop offset="100%" stop-color="#01040a"/>
    </radialGradient>

    <!-- Inner Circle Background (Rich Midnight Oceanic) -->
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

    <!-- Pure Cross Gradient (No bolt, seamless transition) -->
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
  <rect x="20" y="20" width="810" height="910" rx="120" fill="url(#bgGrad)" stroke="#132e54" stroke-width="2"/>

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

  <!-- ============================================================ -->
  <!-- CROSS (Completely INSIDE Circle, with ample top margin)      -->
  <!-- Circle top is at Y=100. Cross top starts at Y=135!           -->
  <!-- Cross bottom ends at Y=355 flush with adjacent black keys!   -->
  <!-- NO bolt, NO center dot!                                      -->
  <!-- ============================================================ -->
  <!-- Vertical Stem: X: 407 to 443 (Width 36), Y: 135 to 355 (Height 220) -->
  <rect x="407" y="135" width="36" height="220" rx="7" fill="url(#crossGrad)" filter="url(#auroraFilter)"/>
  <!-- Horizontal Crossbar: Y: 185 to 221 (Height 36), X: 345 to 505 (Width 160) -->
  <rect x="345" y="185" width="160" height="36" rx="7" fill="url(#crossGrad)" filter="url(#auroraFilter)"/>

  <!-- ============================================================ -->
  <!-- BIG, COMMANDING TYPOGRAPHY WITH HARMONIC WAVE DESIGN         -->
  <!-- ============================================================ -->
  <!-- Primary Title: WORSHIP (Large 64px, Prominent, Glowing) -->
  <text x="425" y="565" text-anchor="middle" font-family="-apple-system, BlinkMacSystemFont, 'Plus Jakarta Sans', 'Inter', sans-serif" font-size="64" font-weight="900" letter-spacing="14" fill="url(#worshipGrad)">WORSHIP</text>

  <!-- Acoustic Soundwave Pulse Visualizer between Titles -->
  <g filter="url(#auroraFilter)">
    <!-- Left Frequency Bars -->
    <line x1="180" y1="620" x2="180" y2="628" stroke="#0077b6" stroke-width="3" stroke-linecap="round"/>
    <line x1="195" y1="614" x2="195" y2="634" stroke="#00b4d8" stroke-width="3.5" stroke-linecap="round"/>
    <line x1="210" y1="604" x2="210" y2="644" stroke="#00b4d8" stroke-width="3.5" stroke-linecap="round"/>
    <line x1="225" y1="612" x2="225" y2="636" stroke="#64ffda" stroke-width="3.5" stroke-linecap="round"/>
    <line x1="240" y1="600" x2="240" y2="648" stroke="#64ffda" stroke-width="4" stroke-linecap="round"/>

    <!-- Harmonic Soundwave Line across the center -->
    <path d="M 260 624 Q 300 596 340 624 T 425 624 T 510 624 T 590 624" fill="none" stroke="url(#auroraRing)" stroke-width="4.5" stroke-linecap="round"/>

    <!-- Right Frequency Bars -->
    <line x1="610" y1="600" x2="610" y2="648" stroke="#64ffda" stroke-width="4" stroke-linecap="round"/>
    <line x1="625" y1="612" x2="625" y2="636" stroke="#64ffda" stroke-width="3.5" stroke-linecap="round"/>
    <line x1="640" y1="604" x2="640" y2="644" stroke="#00b4d8" stroke-width="3.5" stroke-linecap="round"/>
    <line x1="655" y1="614" x2="655" y2="634" stroke="#00b4d8" stroke-width="3.5" stroke-linecap="round"/>
    <line x1="670" y1="620" x2="670" y2="628" stroke="#0077b6" stroke-width="3" stroke-linecap="round"/>
  </g>

  <!-- Secondary Title: COMPANION (Large 40px, Wide Tracking, Mint Neon) -->
  <text x="425" y="710" text-anchor="middle" font-family="-apple-system, BlinkMacSystemFont, 'Plus Jakarta Sans', 'Inter', sans-serif" font-size="40" font-weight="700" letter-spacing="22" fill="#64ffda">COMPANION</text>

  <!-- Grounding Fluid Sine Wave Underline -->
  <path d="M 250 760 C 330 785, 380 745, 425 760 C 470 775, 520 735, 600 760" fill="none" stroke="url(#auroraRing)" stroke-width="3.5" stroke-linecap="round" filter="url(#auroraFilter)"/>
</svg>'''

logo_transparent_svg = logo_dark_svg.replace(
  '<rect x="20" y="20" width="810" height="910" rx="120" fill="url(#bgGrad)" stroke="#132e54" stroke-width="2"/>',
  '<!-- Transparent background for headers and print -->'
)

# ==============================================================================
# 2. ANDROID ADAPTIVE LAYERS (Strict 66% Safe Zone with Contained Circle Emblem)
# ==============================================================================
android_bg_svg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <radialGradient id="bgGrad" cx="50%" cy="40%" r="75%">
      <stop offset="0%" stop-color="#0c213d"/>
      <stop offset="45%" stop-color="#061326"/>
      <stop offset="85%" stop-color="#030914"/>
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

android_fg_svg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <radialGradient id="innerCircleBgFg" cx="50%" cy="32%" r="68%">
      <stop offset="0%" stop-color="#122d52"/>
      <stop offset="55%" stop-color="#08172c"/>
      <stop offset="100%" stop-color="#040b17"/>
    </radialGradient>
    <radialGradient id="auroraGlowFg" cx="50%" cy="35%" r="55%">
      <stop offset="0%" stop-color="#64ffda" stop-opacity="0.55"/>
      <stop offset="35%" stop-color="#00b4d8" stop-opacity="0.28"/>
      <stop offset="100%" stop-color="#000000" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="auroraRingFg" x1="0%" y1="100%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#0077b6"/>
      <stop offset="30%" stop-color="#00b4d8"/>
      <stop offset="70%" stop-color="#64ffda"/>
      <stop offset="100%" stop-color="#bbf7d0"/>
    </linearGradient>
    <linearGradient id="crossGradFg" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#ffffff"/>
      <stop offset="25%" stop-color="#d1fae5"/>
      <stop offset="60%" stop-color="#00b4d8"/>
      <stop offset="100%" stop-color="#04234d"/>
    </linearGradient>
    <filter id="softGlowFg" x="-30%" y="-30%" width="160%" height="160%">
      <feGaussianBlur stdDeviation="10" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
    <clipPath id="circleClipFg">
      <circle cx="512" cy="512" r="230"/>
    </clipPath>
  </defs>

  <circle cx="512" cy="450" r="220" fill="url(#auroraGlowFg)"/>
  <circle cx="512" cy="512" r="268" fill="none" stroke="#64ffda" stroke-opacity="0.22" stroke-width="3" stroke-dasharray="8 10"/>
  <circle cx="512" cy="512" r="302" fill="none" stroke="#00b4d8" stroke-opacity="0.14" stroke-width="2" stroke-dasharray="16 12"/>

  <!-- MAIN CIRCLE (Completely above cross and keys) -->
  <circle cx="512" cy="512" r="230" fill="url(#innerCircleBgFg)" stroke="url(#auroraRingFg)" stroke-width="9" filter="url(#softGlowFg)"/>

  <g clip-path="url(#circleClipFg)">
    <rect x="260" y="512" width="504" height="250" fill="#f0fdf4"/>
    <line x1="335" y1="512" x2="335" y2="745" stroke="#081427" stroke-width="4.5"/>
    <line x1="395" y1="512" x2="395" y2="745" stroke="#081427" stroke-width="4.5"/>
    <line x1="455" y1="512" x2="455" y2="745" stroke="#081427" stroke-width="4.5"/>
    <line x1="569" y1="512" x2="569" y2="745" stroke="#081427" stroke-width="4.5"/>
    <line x1="629" y1="512" x2="629" y2="745" stroke="#081427" stroke-width="4.5"/>
    <line x1="689" y1="512" x2="689" y2="745" stroke="#081427" stroke-width="4.5"/>

    <rect x="318" y="512" width="34" height="106" rx="5" fill="#060e1d"/>
    <rect x="378" y="512" width="34" height="106" rx="5" fill="#060e1d"/>
    <rect x="552" y="512" width="34" height="106" rx="5" fill="#060e1d"/>
    <rect x="612" y="512" width="34" height="106" rx="5" fill="#060e1d"/>
    <rect x="672" y="512" width="34" height="106" rx="5" fill="#060e1d"/>
  </g>

  <g clip-path="url(#circleClipFg)">
    <line x1="265" y1="512" x2="759" y2="512" stroke="url(#auroraRingFg)" stroke-width="6"/>
  </g>

  <!-- Cross inside circle -->
  <rect x="488" y="328" width="48" height="290" rx="9" fill="url(#crossGradFg)" filter="url(#softGlowFg)"/>
  <rect x="407" y="394" width="210" height="48" rx="9" fill="url(#crossGradFg)" filter="url(#softGlowFg)"/>
</svg>'''

android_mono_svg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <clipPath id="circleClipMono">
      <circle cx="512" cy="512" r="230"/>
    </clipPath>
  </defs>

  <circle cx="512" cy="512" r="230" fill="none" stroke="#ffffff" stroke-width="12"/>
  <circle cx="512" cy="512" r="268" fill="none" stroke="#ffffff" stroke-opacity="0.35" stroke-width="3.5" stroke-dasharray="8 10"/>

  <g clip-path="url(#circleClipMono)">
    <rect x="260" y="512" width="504" height="250" fill="#ffffff" fill-opacity="0.32"/>
    <line x1="335" y1="512" x2="335" y2="745" stroke="#000000" stroke-width="4.5"/>
    <line x1="395" y1="512" x2="395" y2="745" stroke="#000000" stroke-width="4.5"/>
    <line x1="455" y1="512" x2="455" y2="745" stroke="#000000" stroke-width="4.5"/>
    <line x1="569" y1="512" x2="569" y2="745" stroke="#000000" stroke-width="4.5"/>
    <line x1="629" y1="512" x2="629" y2="745" stroke="#000000" stroke-width="4.5"/>
    <line x1="689" y1="512" x2="689" y2="745" stroke="#000000" stroke-width="4.5"/>

    <rect x="318" y="512" width="34" height="106" rx="5" fill="#000000"/>
    <rect x="378" y="512" width="34" height="106" rx="5" fill="#000000"/>
    <rect x="552" y="512" width="34" height="106" rx="5" fill="#000000"/>
    <rect x="612" y="512" width="34" height="106" rx="5" fill="#000000"/>
    <rect x="672" y="512" width="34" height="106" rx="5" fill="#000000"/>
  </g>

  <g clip-path="url(#circleClipMono)">
    <line x1="265" y1="512" x2="759" y2="512" stroke="#ffffff" stroke-width="6"/>
  </g>

  <rect x="488" y="328" width="48" height="290" rx="9" fill="#ffffff"/>
  <rect x="407" y="394" width="210" height="48" rx="9" fill="#ffffff"/>
</svg>'''

# ==============================================================================
# 3. ANDROID UI SHAPE PREVIEWS
# ==============================================================================
pixel_preview_svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <clipPath id="pixelCircleClip">
      <circle cx="512" cy="512" r="340"/>
    </clipPath>
  </defs>
  <rect width="1024" height="1024" rx="200" fill="#121418"/>
  <g clip-path="url(#pixelCircleClip)">
    {android_bg_svg[android_bg_svg.find("<defs>"):android_bg_svg.rfind("</svg>")]}
    {android_fg_svg[android_fg_svg.find("<defs>"):android_fg_svg.rfind("</svg>")]}
  </g>
  <circle cx="512" cy="512" r="340" fill="none" stroke="#ffffff" stroke-opacity="0.12" stroke-width="2"/>
  <text x="512" y="930" text-anchor="middle" font-family="-apple-system, sans-serif" font-size="34" font-weight="600" fill="#e0e2ec">Google Pixel UI (Circle Mask)</text>
</svg>'''

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
  <rect x="172" y="172" width="680" height="680" rx="220" fill="none" stroke="#ffffff" stroke-opacity="0.14" stroke-width="2"/>
  <text x="512" y="930" text-anchor="middle" font-family="-apple-system, sans-serif" font-size="34" font-weight="600" fill="#e0e2ec">Samsung One UI (Squircle Mask)</text>
</svg>'''

material_you_preview_svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <clipPath id="myClip">
      <circle cx="512" cy="512" r="340"/>
    </clipPath>
  </defs>
  <rect width="1024" height="1024" rx="200" fill="#121418"/>
  <g clip-path="url(#myClip)">
    <rect width="1024" height="1024" fill="#1b4d3e"/>
    <g fill="#a7f3d0" stroke="#a7f3d0">
      {android_mono_svg.replace('#ffffff', '#a7f3d0')[android_mono_svg.find("<defs>"):android_mono_svg.rfind("</svg>")]}
    </g>
  </g>
  <circle cx="512" cy="512" r="340" fill="none" stroke="#a7f3d0" stroke-opacity="0.2" stroke-width="2"/>
  <text x="512" y="930" text-anchor="middle" font-family="-apple-system, sans-serif" font-size="34" font-weight="600" fill="#a7f3d0">Android 13/14+ Material You (Dynamic Themed)</text>
</svg>'''

# ==============================================================================
# 4. iOS STANDARDS (Liquid Glass, Contained Circle)
# ==============================================================================
ios_icon_svg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <radialGradient id="iosBg" cx="50%" cy="28%" r="78%">
      <stop offset="0%" stop-color="#0e2343"/>
      <stop offset="45%" stop-color="#08152a"/>
      <stop offset="85%" stop-color="#030814"/>
      <stop offset="100%" stop-color="#010309"/>
    </radialGradient>
    <radialGradient id="iosInnerCircleBg" cx="50%" cy="30%" r="68%">
      <stop offset="0%" stop-color="#143158"/>
      <stop offset="55%" stop-color="#09182e"/>
      <stop offset="100%" stop-color="#040b17"/>
    </radialGradient>
    <radialGradient id="iosCrossAura" cx="50%" cy="32%" r="55%">
      <stop offset="0%" stop-color="#64ffda" stop-opacity="0.55"/>
      <stop offset="35%" stop-color="#00b4d8" stop-opacity="0.28"/>
      <stop offset="100%" stop-color="#000000" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="iosRingGrad" x1="0%" y1="100%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#0077b6"/>
      <stop offset="30%" stop-color="#00b4d8"/>
      <stop offset="70%" stop-color="#64ffda"/>
      <stop offset="100%" stop-color="#bbf7d0"/>
    </linearGradient>
    <linearGradient id="iosCrossGrad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#ffffff"/>
      <stop offset="25%" stop-color="#d1fae5"/>
      <stop offset="60%" stop-color="#00b4d8"/>
      <stop offset="100%" stop-color="#04234d"/>
    </linearGradient>
    <linearGradient id="iosGlassHighlight" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#ffffff" stop-opacity="0.24"/>
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

  <rect width="1024" height="1024" fill="url(#iosBg)"/>
  <path d="M 0 0 L 1024 0 L 1024 450 L 0 780 Z" fill="url(#iosGlassHighlight)"/>
  <circle cx="512" cy="420" r="310" fill="url(#iosCrossAura)"/>
  <circle cx="512" cy="512" r="365" fill="none" stroke="#64ffda" stroke-opacity="0.20" stroke-width="3" stroke-dasharray="12 14"/>
  <circle cx="512" cy="512" r="410" fill="none" stroke="#00b4d8" stroke-opacity="0.12" stroke-width="2.5" stroke-dasharray="20 16"/>

  <!-- Main Circle Bezel -->
  <circle cx="512" cy="512" r="310" fill="url(#iosInnerCircleBg)" stroke="url(#iosRingGrad)" stroke-width="12" filter="url(#iosGlow)"/>

  <g clip-path="url(#iosCircleClip)">
    <rect x="180" y="512" width="664" height="340" fill="#f0fdf4"/>
    <line x1="280" y1="512" x2="280" y2="830" stroke="#081427" stroke-width="5"/>
    <line x1="360" y1="512" x2="360" y2="830" stroke="#081427" stroke-width="5"/>
    <line x1="440" y1="512" x2="440" y2="830" stroke="#081427" stroke-width="5"/>
    <line x1="584" y1="512" x2="584" y2="830" stroke="#081427" stroke-width="5"/>
    <line x1="664" y1="512" x2="664" y2="830" stroke="#081427" stroke-width="5"/>
    <line x1="744" y1="512" x2="744" y2="830" stroke="#081427" stroke-width="5"/>

    <rect x="258" y="512" width="46" height="145" rx="6" fill="#060e1d"/>
    <rect x="338" y="512" width="46" height="145" rx="6" fill="#060e1d"/>
    <rect x="562" y="512" width="46" height="145" rx="6" fill="#060e1d"/>
    <rect x="642" y="512" width="46" height="145" rx="6" fill="#060e1d"/>
    <rect x="722" y="512" width="46" height="145" rx="6" fill="#060e1d"/>
  </g>

  <g clip-path="url(#iosCircleClip)">
    <line x1="190" y1="512" x2="834" y2="512" stroke="url(#iosRingGrad)" stroke-width="8"/>
  </g>

  <!-- Cross inside circle -->
  <rect x="479" y="264" width="66" height="393" rx="12" fill="url(#iosCrossGrad)" filter="url(#iosGlow)"/>
  <rect x="370" y="352" width="284" height="64" rx="12" fill="url(#iosCrossGrad)" filter="url(#iosGlow)"/>
  <path d="M 479 264 L 545 264 L 535 320 L 489 320 Z" fill="#ffffff" fill-opacity="0.4"/>
</svg>'''

ios_dark_svg = ios_icon_svg.replace(
  '<rect width="1024" height="1024" fill="url(#iosBg)"/>',
  '<rect width="1024" height="1024" fill="#03060a"/>'
)

ios_preview_svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <clipPath id="iosSquircleClip">
      <rect x="112" y="60" width="800" height="800" rx="180"/>
    </clipPath>
  </defs>
  <rect width="1024" height="1024" fill="#0b0e14"/>
  <g clip-path="url(#iosSquircleClip)">
    <g transform="translate(112, 60) scale(0.78125)">
      {ios_icon_svg[ios_icon_svg.find("<defs>"):ios_icon_svg.rfind("</svg>")]}
    </g>
  </g>
  <rect x="112" y="60" width="800" height="800" rx="180" fill="none" stroke="#ffffff" stroke-opacity="0.16" stroke-width="2.5"/>
  <text x="512" y="930" text-anchor="middle" font-family="-apple-system, BlinkMacSystemFont, sans-serif" font-size="34" font-weight="600" fill="#f5f5f7">Apple iOS Home Screen (Continuous Squircle)</text>
</svg>'''

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
  (f"{base_dir}/ios/AppIcon-1024-dark.svg", ios_dark_svg),
  (f"{base_dir}/ios/preview/ios_home_screen_preview.svg", ios_preview_svg),
]

for p, c in files_to_save:
  with open(p, "w") as f:
    f.write(c)

# Rasterize with qlmanage
for root, dirs, files in os.walk(base_dir):
  for f in files:
    if f.endswith(".svg"):
      full_path = os.path.join(root, f)
      subprocess.run(["qlmanage", "-t", "-s", "1024", "-o", root, full_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
      src_png = os.path.join(root, f + ".png")
      target_png = os.path.join(root, f.replace(".svg", ".png"))
      if os.path.exists(src_png):
        os.replace(src_png, target_png)

# Copy to artifacts directory
artifact_copies = [
  (f"{base_dir}/logo/worship_companion_logo_dark.png", f"{artifact_dir}/worship_companion_logo_dark.png"),
  (f"{base_dir}/logo/worship_companion_logo_transparent.png", f"{artifact_dir}/worship_companion_logo_transparent.png"),
  (f"{base_dir}/android/preview_shapes/pixel_ui_circle_preview.png", f"{artifact_dir}/pixel_ui_circle_preview.png"),
  (f"{base_dir}/android/preview_shapes/samsung_oneui_squircle_preview.png", f"{artifact_dir}/samsung_oneui_squircle_preview.png"),
  (f"{base_dir}/android/preview_shapes/material_you_themed_preview.png", f"{artifact_dir}/material_you_themed_preview.png"),
  (f"{base_dir}/ios/preview/ios_home_screen_preview.png", f"{artifact_dir}/ios_home_screen_preview.png"),
  (f"{base_dir}/ios/AppIcon-1024.png", f"{artifact_dir}/ios_appicon_1024.png"),
  (f"{base_dir}/ios/AppIcon-1024-dark.png", f"{artifact_dir}/ios_appicon_dark.png"),
]

for src, dst in artifact_copies:
  subprocess.run(["cp", src, dst], check=True)

# Generate Android Mipmap densities via sips
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
res_dir = f"{base_dir}/android/res"

for folder, (launcher_sz, layer_sz) in densities.items():
  d_path = os.path.join(res_dir, folder)
  os.makedirs(d_path, exist_ok=True)
  subprocess.run(["sips", "-z", str(layer_sz), str(layer_sz), bg_src, "--out", os.path.join(d_path, "ic_launcher_background.png")], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
  subprocess.run(["sips", "-z", str(layer_sz), str(layer_sz), fg_src, "--out", os.path.join(d_path, "ic_launcher_foreground.png")], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
  subprocess.run(["sips", "-z", str(layer_sz), str(layer_sz), mono_src, "--out", os.path.join(d_path, "ic_launcher_monochrome.png")], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
  subprocess.run(["sips", "-z", str(launcher_sz), str(launcher_sz), ios_src, "--out", os.path.join(d_path, "ic_launcher.png")], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
  subprocess.run(["sips", "-z", str(launcher_sz), str(launcher_sz), ios_src, "--out", os.path.join(d_path, "ic_launcher_round.png")], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

# Generate iOS AppIcon.appiconset sizes
appiconset_dir = f"{base_dir}/ios/AppIcon.appiconset"
ios_sizes = [
    ("Icon-App-20x20@1x.png", 20),
    ("Icon-App-20x20@2x.png", 40),
    ("Icon-App-20x20@3x.png", 60),
    ("Icon-App-29x29@1x.png", 29),
    ("Icon-App-29x29@2x.png", 58),
    ("Icon-App-29x29@3x.png", 87),
    ("Icon-App-40x40@1x.png", 40),
    ("Icon-App-40x40@2x.png", 80),
    ("Icon-App-40x40@3x.png", 120),
    ("Icon-App-60x60@2x.png", 120),
    ("Icon-App-60x60@3x.png", 180),
    ("Icon-App-76x76@1x.png", 76),
    ("Icon-App-76x76@2x.png", 152),
    ("Icon-App-83.5x83.5@2x.png", 167),
    ("ItunesArtwork@2x.png", 1024)
]
for fname, sz in ios_sizes:
  subprocess.run(["sips", "-z", str(sz), str(sz), ios_src, "--out", os.path.join(appiconset_dir, fname)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

print("All contained circle assets successfully generated and rasterized!")
