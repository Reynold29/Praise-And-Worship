import os
import subprocess

artifact_dir = "/Users/reyzie29/.gemini/antigravity-ide/brain/04d35cd7-a681-40a1-9d4b-726634c421f7"

# Concept 5: Aurora & Harmonic Soundwaves (Teal, Cyan, Emerald & Radiant Pulse)
svg5 = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 850" width="800" height="850">
  <defs>
    <radialGradient id="bgGrad5" cx="50%" cy="30%" r="75%">
      <stop offset="0%" stop-color="#0a192f"/>
      <stop offset="50%" stop-color="#07101f"/>
      <stop offset="100%" stop-color="#03070d"/>
    </radialGradient>
    <radialGradient id="auroraGlow5" cx="50%" cy="40%" r="60%">
      <stop offset="0%" stop-color="#64ffda" stop-opacity="0.5"/>
      <stop offset="35%" stop-color="#00b4d8" stop-opacity="0.3"/>
      <stop offset="70%" stop-color="#7209b7" stop-opacity="0.15"/>
      <stop offset="100%" stop-color="#000000" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="auroraGrad5" x1="0%" y1="100%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#0077b6"/>
      <stop offset="35%" stop-color="#00b4d8"/>
      <stop offset="70%" stop-color="#64ffda"/>
      <stop offset="100%" stop-color="#bbf7d0"/>
    </linearGradient>
    <linearGradient id="crossAurora5" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#ffffff"/>
      <stop offset="25%" stop-color="#bbf7d0"/>
      <stop offset="65%" stop-color="#00b4d8"/>
      <stop offset="100%" stop-color="#03045e"/>
    </linearGradient>
    <filter id="auroraBlur5" x="-25%" y="-25%" width="150%" height="150%">
      <feGaussianBlur stdDeviation="9" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
    <clipPath id="circleClip5">
      <circle cx="400" cy="330" r="148"/>
    </clipPath>
  </defs>

  <!-- Background App Card -->
  <rect x="20" y="20" width="760" height="810" rx="120" fill="url(#bgGrad5)" stroke="#112240" stroke-width="2"/>

  <!-- Aurora Glow Behind Cross -->
  <circle cx="400" cy="220" r="150" fill="url(#auroraGlow5)"/>

  <!-- Harmonic Sound Wave Rings around emblem -->
  <circle cx="400" cy="330" r="175" fill="none" stroke="#64ffda" stroke-opacity="0.25" stroke-width="2" stroke-dasharray="6 8"/>
  <circle cx="400" cy="330" r="205" fill="none" stroke="#00b4d8" stroke-opacity="0.18" stroke-width="1.5" stroke-dasharray="14 10"/>
  <circle cx="400" cy="330" r="235" fill="none" stroke="#64ffda" stroke-opacity="0.08" stroke-width="1"/>

  <!-- Outer Ring with Teal-Cyan Aurora Gradient -->
  <circle cx="400" cy="330" r="150" fill="#0b1a30" fill-opacity="0.85" stroke="url(#auroraGrad5)" stroke-width="6" filter="url(#auroraBlur5)"/>

  <!-- Piano Keys Inside Circle -->
  <g clip-path="url(#circleClip5)">
    <!-- Pristine Ivory Keys -->
    <rect x="230" y="330" width="340" height="160" fill="#f0fdf4"/>
    
    <!-- Fine Key Dividers -->
    <line x1="280" y1="330" x2="280" y2="480" stroke="#0b172a" stroke-width="3"/>
    <line x1="320" y1="330" x2="320" y2="480" stroke="#0b172a" stroke-width="3"/>
    <line x1="360" y1="330" x2="360" y2="480" stroke="#0b172a" stroke-width="3"/>
    <line x1="440" y1="330" x2="440" y2="480" stroke="#0b172a" stroke-width="3"/>
    <line x1="480" y1="330" x2="480" y2="480" stroke="#0b172a" stroke-width="3"/>
    <line x1="520" y1="330" x2="520" y2="480" stroke="#0b172a" stroke-width="3"/>

    <!-- Black Piano Keys -->
    <rect x="268" y="330" width="24" height="85" rx="4" fill="#091424"/>
    <rect x="308" y="330" width="24" height="85" rx="4" fill="#091424"/>
    <rect x="428" y="330" width="24" height="85" rx="4" fill="#091424"/>
    <rect x="468" y="330" width="24" height="85" rx="4" fill="#091424"/>
    <rect x="508" y="330" width="24" height="85" rx="4" fill="#091424"/>
  </g>

  <!-- Horizontal Divider -->
  <line x1="250" y1="330" x2="550" y2="330" stroke="url(#auroraGrad5)" stroke-width="4.5" stroke-linecap="round"/>

  <!-- Cross Ascending from Center Key -->
  <rect x="382" y="115" width="36" height="340" rx="8" fill="url(#crossAurora5)" filter="url(#auroraBlur5)"/>
  <rect x="325" y="185" width="150" height="36" rx="8" fill="url(#crossAurora5)" filter="url(#auroraBlur5)"/>

  <!-- Glowing Center Starburst -->
  <circle cx="400" cy="203" r="8" fill="#ffffff" filter="url(#auroraBlur5)"/>

  <!-- Typography -->
  <text x="400" y="605" text-anchor="middle" font-family="-apple-system, BlinkMacSystemFont, 'Plus Jakarta Sans', Inter, sans-serif" font-size="46" font-weight="800" letter-spacing="10" fill="#f0fdf4">WORSHIP</text>
  <text x="400" y="660" text-anchor="middle" font-family="-apple-system, BlinkMacSystemFont, 'Plus Jakarta Sans', Inter, sans-serif" font-size="28" font-weight="600" letter-spacing="16" fill="#64ffda">COMPANION</text>

  <!-- Soundwave Accent -->
  <path d="M 330 705 Q 365 695 400 705 T 470 705" fill="none" stroke="#64ffda" stroke-width="2.5" stroke-linecap="round"/>
</svg>'''

svg5_path = os.path.join(artifact_dir, "piano_cross_v5_aurora.svg")
with open(svg5_path, "w") as f:
    f.write(svg5)
print(f"Saved {svg5_path}")
