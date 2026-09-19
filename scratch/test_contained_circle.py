import os
import subprocess

artifact_dir = "/Users/reyzie29/.gemini/antigravity-ide/brain/04d35cd7-a681-40a1-9d4b-726634c421f7"

# We want:
# 1. Circle comes ABOVE the cross - keys and cross are totally INSIDE the circle.
# 2. WORSHIP COMPANION in text with the wave design, BIG and visible.
# 3. Concept 5 aurora colors (Oceanic navy, radiant cyan, mint, deep sapphire).
# 4. No bolt in the middle of the cross.

svg_test = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 850 920" width="850" height="920">
  <defs>
    <!-- Background Card Gradient -->
    <radialGradient id="bgGrad" cx="50%" cy="28%" r="75%">
      <stop offset="0%" stop-color="#0b1e38"/>
      <stop offset="55%" stop-color="#061224"/>
      <stop offset="100%" stop-color="#02060e"/>
    </radialGradient>

    <!-- Inner Circle Dark Navy Fill -->
    <radialGradient id="innerCircleBg" cx="50%" cy="35%" r="65%">
      <stop offset="0%" stop-color="#0f294a"/>
      <stop offset="60%" stop-color="#081528"/>
      <stop offset="100%" stop-color="#040b17"/>
    </radialGradient>

    <!-- Soft Ambient Aurora Glow -->
    <radialGradient id="auroraGlow" cx="50%" cy="30%" r="55%">
      <stop offset="0%" stop-color="#64ffda" stop-opacity="0.5"/>
      <stop offset="35%" stop-color="#00b4d8" stop-opacity="0.25"/>
      <stop offset="70%" stop-color="#023e8a" stop-opacity="0.1"/>
      <stop offset="100%" stop-color="#000000" stop-opacity="0"/>
    </radialGradient>

    <!-- Glowing Outer Ring Gradient -->
    <linearGradient id="auroraRing" x1="0%" y1="100%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#0077b6"/>
      <stop offset="30%" stop-color="#00b4d8"/>
      <stop offset="70%" stop-color="#64ffda"/>
      <stop offset="100%" stop-color="#bbf7d0"/>
    </linearGradient>

    <!-- Cross Gradient -->
    <linearGradient id="crossGrad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#ffffff"/>
      <stop offset="25%" stop-color="#cbfbf0"/>
      <stop offset="60%" stop-color="#00b4d8"/>
      <stop offset="100%" stop-color="#042048"/>
    </linearGradient>

    <!-- Text Gradient for WORSHIP -->
    <linearGradient id="worshipTextGrad" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#ffffff"/>
      <stop offset="50%" stop-color="#f0fdf4"/>
      <stop offset="100%" stop-color="#bbf7d0"/>
    </linearGradient>

    <!-- Glow Filter -->
    <filter id="softGlow" x="-30%" y="-30%" width="160%" height="160%">
      <feGaussianBlur stdDeviation="8" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>

    <!-- Clip Path for Piano Keys (strictly within lower half of circle) -->
    <clipPath id="circleClip">
      <circle cx="425" cy="270" r="168"/>
    </clipPath>
  </defs>

  <!-- App Card Background -->
  <rect x="20" y="20" width="810" height="880" rx="120" fill="url(#bgGrad)" stroke="#132b4f" stroke-width="2"/>

  <!-- Halo Aura Behind Cross Inside Circle -->
  <circle cx="425" cy="220" r="160" fill="url(#auroraGlow)"/>

  <!-- Concentric Acoustic Resonance Rings (Subtle outside circle) -->
  <circle cx="425" cy="270" r="195" fill="none" stroke="#64ffda" stroke-opacity="0.18" stroke-width="2" stroke-dasharray="6 8"/>
  <circle cx="425" cy="270" r="222" fill="none" stroke="#00b4d8" stroke-opacity="0.12" stroke-width="1.5" stroke-dasharray="14 10"/>

  <!-- ============================================================ -->
  <!-- MAIN CIRCLE (Comes completely ABOVE the cross & keys)       -->
  <!-- Cross and keys are 100% inside this circle!                  -->
  <!-- ============================================================ -->
  <circle cx="425" cy="270" r="170" fill="url(#innerCircleBg)" stroke="url(#auroraRing)" stroke-width="7" filter="url(#softGlow)"/>

  <!-- Piano Keyboard (Lower Half of Circle) -->
  <g clip-path="url(#circleClip)">
    <!-- White Keys Base -->
    <rect x="240" y="270" width="370" height="180" fill="#f0fdf4"/>

    <!-- Key Dividers -->
    <line x1="295" y1="270" x2="295" y2="440" stroke="#081427" stroke-width="3.5"/>
    <line x1="340" y1="270" x2="340" y2="440" stroke="#081427" stroke-width="3.5"/>
    <line x1="385" y1="270" x2="385" y2="440" stroke="#081427" stroke-width="3.5"/>
    <line x1="465" y1="270" x2="465" y2="440" stroke="#081427" stroke-width="3.5"/>
    <line x1="510" y1="270" x2="510" y2="440" stroke="#081427" stroke-width="3.5"/>
    <line x1="555" y1="270" x2="555" y2="440" stroke="#081427" stroke-width="3.5"/>

    <!-- Black Keys (Flush at Y = 350) -->
    <rect x="282" y="270" width="26" height="80" rx="4" fill="#060e1d"/>
    <rect x="327" y="270" width="26" height="80" rx="4" fill="#060e1d"/>
    <rect x="452" y="270" width="26" height="80" rx="4" fill="#060e1d"/>
    <rect x="497" y="270" width="26" height="80" rx="4" fill="#060e1d"/>
    <rect x="542" y="270" width="26" height="80" rx="4" fill="#060e1d"/>
  </g>

  <!-- Horizontal Keyboard Shelf Inside Circle -->
  <g clip-path="url(#circleClip)">
    <line x1="240" y1="270" x2="610" y2="270" stroke="url(#auroraRing)" stroke-width="4.5"/>
  </g>

  <!-- ============================================================ -->
  <!-- CROSS: Completely inside circle!                             -->
  <!-- Circle top is at Y=100. Cross top starts safely at Y=135!    -->
  <!-- Cross bottom terminates at Y=350 flush with adjacent keys!   -->
  <!-- No bolt in the middle!                                       -->
  <!-- ============================================================ -->
  <!-- Vertical Stem: X: 407 to 443 (Width 36), Y: 135 to 350 (Height 215) -->
  <rect x="407" y="135" width="36" height="215" rx="7" fill="url(#crossGrad)" filter="url(#softGlow)"/>

  <!-- Horizontal Crossbar: Y: 185 to 221 (Height 36), X: 345 to 505 (Width 160) -->
  <rect x="345" y="185" width="160" height="36" rx="7" fill="url(#crossGrad)" filter="url(#softGlow)"/>

  <!-- ============================================================ -->
  <!-- TYPOGRAPHY + PROMINENT SOUNDWAVE DESIGN (Big & Visible)      -->
  <!-- ============================================================ -->
  <!-- Primary Title: WORSHIP (Large, prominent, glowing) -->
  <text x="425" y="555" text-anchor="middle" font-family="-apple-system, BlinkMacSystemFont, 'Plus Jakarta Sans', 'Inter', sans-serif" font-size="62" font-weight="900" letter-spacing="14" fill="url(#worshipTextGrad)">WORSHIP</text>

  <!-- Dynamic Acoustic Wave Visualizer in the Center (Eye-catching, musical) -->
  <g filter="url(#softGlow)">
    <!-- Central Soundwave Bars (Harmonic frequencies expanding from center) -->
    <line x1="220" y1="605" x2="220" y2="615" stroke="#0077b6" stroke-width="3.5" stroke-linecap="round"/>
    <line x1="236" y1="598" x2="236" y2="622" stroke="#00b4d8" stroke-width="3.5" stroke-linecap="round"/>
    <line x1="252" y1="588" x2="252" y2="632" stroke="#00b4d8" stroke-width="3.5" stroke-linecap="round"/>
    <line x1="268" y1="595" x2="268" y2="625" stroke="#64ffda" stroke-width="3.5" stroke-linecap="round"/>

    <!-- Flowing Continuous Audio Wave Line across the center -->
    <path d="M 285 610 Q 320 585 355 610 T 425 610 T 495 610 T 565 610" fill="none" stroke="url(#auroraRing)" stroke-width="4" stroke-linecap="round"/>

    <!-- Right Soundwave Bars -->
    <line x1="582" y1="595" x2="582" y2="625" stroke="#64ffda" stroke-width="3.5" stroke-linecap="round"/>
    <line x1="598" y1="588" x2="598" y2="632" stroke="#00b4d8" stroke-width="3.5" stroke-linecap="round"/>
    <line x1="614" y1="598" x2="614" y2="622" stroke="#00b4d8" stroke-width="3.5" stroke-linecap="round"/>
    <line x1="630" y1="605" x2="630" y2="615" stroke="#0077b6" stroke-width="3.5" stroke-linecap="round"/>
  </g>

  <!-- Secondary Title: COMPANION (Large, wide-tracked, glowing mint) -->
  <text x="425" y="695" text-anchor="middle" font-family="-apple-system, BlinkMacSystemFont, 'Plus Jakarta Sans', 'Inter', sans-serif" font-size="38" font-weight="700" letter-spacing="22" fill="#64ffda">COMPANION</text>

  <!-- Grounding Acoustic Wave Underline (Sleek fluid audio wavelength) -->
  <path d="M 260 740 Q 342 760 425 740 T 590 740" fill="none" stroke="url(#auroraRing)" stroke-width="3.5" stroke-linecap="round" filter="url(#softGlow)"/>
  <circle cx="425" cy="740" r="4.5" fill="#ffffff" filter="url(#softGlow)"/>
</svg>'''

svg_path = os.path.join(artifact_dir, "test_contained_circle.svg")
with open(svg_path, "w") as f:
    f.write(svg_test)

subprocess.run(["qlmanage", "-t", "-s", "1024", "-o", artifact_dir, svg_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
if os.path.exists(os.path.join(artifact_dir, "test_contained_circle.svg.png")):
    os.replace(os.path.join(artifact_dir, "test_contained_circle.svg.png"), os.path.join(artifact_dir, "test_contained_circle.png"))

print("Saved test_contained_circle.png")
