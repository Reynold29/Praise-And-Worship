import os

artifact_dir = "/Users/reyzie29/.gemini/antigravity-ide/brain/04d35cd7-a681-40a1-9d4b-726634c421f7"

# -------------------------------------------------------------
# Concept E: Cathedral Stained Glass & Jewel Light (Artistic & Sacred)
# -------------------------------------------------------------
svg_jewel = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 850" width="800" height="850">
  <defs>
    <radialGradient id="bgJewel" cx="50%" cy="32%" r="75%">
      <stop offset="0%" stop-color="#18112b"/>
      <stop offset="60%" stop-color="#0b0717"/>
      <stop offset="100%" stop-color="#04020a"/>
    </radialGradient>
    <radialGradient id="jewelHalo" cx="50%" cy="25%" r="55%">
      <stop offset="0%" stop-color="#ffd56b" stop-opacity="0.55"/>
      <stop offset="35%" stop-color="#ff007f" stop-opacity="0.25"/>
      <stop offset="70%" stop-color="#7928ca" stop-opacity="0.15"/>
      <stop offset="100%" stop-color="#000000" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="goldFrame" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#fff2a1"/>
      <stop offset="25%" stop-color="#d4af37"/>
      <stop offset="60%" stop-color="#aa771c"/>
      <stop offset="100%" stop-color="#ffd257"/>
    </linearGradient>
    <linearGradient id="rubyFacet" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#ff4b72"/>
      <stop offset="100%" stop-color="#99002b"/>
    </linearGradient>
    <linearGradient id="sapphireFacet" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#4facfe"/>
      <stop offset="100%" stop-color="#0039a6"/>
    </linearGradient>
    <linearGradient id="amberFacet" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#ffe259"/>
      <stop offset="100%" stop-color="#ffa751"/>
    </linearGradient>
    <linearGradient id="emeraldFacet" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#2af598"/>
      <stop offset="100%" stop-color="#009efd"/>
    </linearGradient>
    <linearGradient id="amethystFacet" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#b827fc"/>
      <stop offset="100%" stop-color="#4e085f"/>
    </linearGradient>
    <filter id="jewelGlow" x="-25%" y="-25%" width="150%" height="150%">
      <feGaussianBlur stdDeviation="8" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
    <clipPath id="circleClipJewel">
      <circle cx="400" cy="330" r="148"/>
    </clipPath>
  </defs>

  <!-- Background App Card -->
  <rect x="20" y="20" width="760" height="810" rx="120" fill="url(#bgJewel)" stroke="#2b1a45" stroke-width="2"/>

  <!-- Halo Behind Cross -->
  <circle cx="400" cy="200" r="160" fill="url(#jewelHalo)"/>

  <!-- Decorative Sacred Rays Behind Emblem -->
  <g stroke="url(#goldFrame)" stroke-opacity="0.2" stroke-width="1.5">
    <line x1="400" y1="130" x2="400" y2="70"/>
    <line x1="330" y1="140" x2="280" y2="90"/>
    <line x1="470" y1="140" x2="520" y2="90"/>
    <line x1="280" y1="200" x2="220" y2="170"/>
    <line x1="520" y1="200" x2="580" y2="170"/>
  </g>

  <!-- Outer Ring with Gold Leading -->
  <circle cx="400" cy="330" r="150" fill="#110a24" fill-opacity="0.9" stroke="url(#goldFrame)" stroke-width="7" filter="url(#jewelGlow)"/>

  <!-- Lower Piano Keyboard -->
  <g clip-path="url(#circleClipJewel)">
    <!-- Ivory Keys -->
    <rect x="230" y="330" width="340" height="160" fill="#fcf8f0"/>
    <!-- Key Lines -->
    <line x1="280" y1="330" x2="280" y2="480" stroke="#160e2b" stroke-width="3"/>
    <line x1="320" y1="330" x2="320" y2="480" stroke="#160e2b" stroke-width="3"/>
    <line x1="360" y1="330" x2="360" y2="480" stroke="#160e2b" stroke-width="3"/>
    <line x1="440" y1="330" x2="440" y2="480" stroke="#160e2b" stroke-width="3"/>
    <line x1="480" y1="330" x2="480" y2="480" stroke="#160e2b" stroke-width="3"/>
    <line x1="520" y1="330" x2="520" y2="480" stroke="#160e2b" stroke-width="3"/>

    <!-- Black Keys -->
    <rect x="268" y="330" width="24" height="86" rx="4" fill="#0d081b"/>
    <rect x="308" y="330" width="24" height="86" rx="4" fill="#0d081b"/>
    <rect x="428" y="330" width="24" height="86" rx="4" fill="#0d081b"/>
    <rect x="468" y="330" width="24" height="86" rx="4" fill="#0d081b"/>
    <rect x="508" y="330" width="24" height="86" rx="4" fill="#0d081b"/>
  </g>

  <!-- Horizontal Gold Shelf -->
  <line x1="250" y1="330" x2="550" y2="330" stroke="url(#goldFrame)" stroke-width="5" stroke-linecap="round"/>

  <!-- Stained Glass Faceted Cross -->
  <!-- Upper Vertical Head -->
  <polygon points="383,115 417,115 417,185 383,185" fill="url(#amberFacet)" stroke="url(#goldFrame)" stroke-width="2"/>
  <polygon points="383,115 400,150 417,115" fill="#ffffff" fill-opacity="0.4"/>
  <!-- Left Cross Arm -->
  <polygon points="325,185 383,185 383,221 325,221" fill="url(#rubyFacet)" stroke="url(#goldFrame)" stroke-width="2"/>
  <polygon points="325,185 354,203 325,221" fill="#ffffff" fill-opacity="0.3"/>
  <!-- Right Cross Arm -->
  <polygon points="417,185 475,185 475,221 417,221" fill="url(#sapphireFacet)" stroke="url(#goldFrame)" stroke-width="2"/>
  <polygon points="475,185 446,203 475,221" fill="#ffffff" fill-opacity="0.3"/>
  <!-- Center Intersection Gem -->
  <polygon points="383,185 417,185 417,221 383,221" fill="url(#emeraldFacet)" stroke="url(#goldFrame)" stroke-width="2"/>
  <!-- Diamond Star Center Overlay -->
  <polygon points="400,189 411,203 400,217 389,203" fill="#ffffff" fill-opacity="0.9" filter="url(#jewelGlow)"/>

  <!-- Lower Cross Stem Rising from Center Piano Key -->
  <polygon points="383,221 417,221 417,330 383,330" fill="url(#amethystFacet)" stroke="url(#goldFrame)" stroke-width="2"/>
  <polygon points="383,330 417,330 417,450 383,450" fill="url(#sapphireFacet)" stroke="url(#goldFrame)" stroke-width="2"/>

  <!-- Typography -->
  <text x="400" y="605" text-anchor="middle" font-family="'Cinzel', Georgia, serif" font-size="46" font-weight="800" letter-spacing="11" fill="url(#goldFrame)">WORSHIP</text>
  <text x="400" y="660" text-anchor="middle" font-family="-apple-system, BlinkMacSystemFont, 'Plus Jakarta Sans', sans-serif" font-size="28" font-weight="600" letter-spacing="16" fill="#e0b0ff">COMPANION</text>

  <!-- Accent -->
  <polygon points="400,698 406,704 400,710 394,704" fill="url(#goldFrame)"/>
  <line x1="300" y1="704" x2="380" y2="704" stroke="url(#goldFrame)" stroke-opacity="0.5" stroke-width="1.5"/>
  <line x1="420" y1="704" x2="500" y2="704" stroke="url(#goldFrame)" stroke-opacity="0.5" stroke-width="1.5"/>
</svg>'''

# -------------------------------------------------------------
# Concept F: Full-Bleed App Icon (Direct Home Screen Presence)
# -------------------------------------------------------------
svg_appicon = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    <radialGradient id="iconBg" cx="50%" cy="35%" r="70%">
      <stop offset="0%" stop-color="#16254c"/>
      <stop offset="45%" stop-color="#0c142b"/>
      <stop offset="100%" stop-color="#050812"/>
    </radialGradient>
    <radialGradient id="crossAuraIcon" cx="50%" cy="40%" r="55%">
      <stop offset="0%" stop-color="#ffd56b" stop-opacity="0.6"/>
      <stop offset="40%" stop-color="#00f2fe" stop-opacity="0.3"/>
      <stop offset="100%" stop-color="#000000" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="neonRingIcon" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#00f2fe"/>
      <stop offset="35%" stop-color="#4facfe"/>
      <stop offset="70%" stop-color="#ffd56b"/>
      <stop offset="100%" stop-color="#ff7b00"/>
    </linearGradient>
    <linearGradient id="crossGradIcon" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#ffffff"/>
      <stop offset="25%" stop-color="#ffe6a7"/>
      <stop offset="60%" stop-color="#00f2fe"/>
      <stop offset="100%" stop-color="#0d38a0"/>
    </linearGradient>
    <filter id="iconGlow" x="-30%" y="-30%" width="160%" height="160%">
      <feGaussianBlur stdDeviation="14" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
    <clipPath id="circleClipIcon">
      <circle cx="512" cy="512" r="330"/>
    </clipPath>
  </defs>

  <!-- iOS App Icon Squircle Background -->
  <rect x="0" y="0" width="1024" height="1024" rx="224" fill="url(#iconBg)"/>

  <!-- Halo Aura Behind Cross -->
  <circle cx="512" cy="380" r="350" fill="url(#crossAuraIcon)"/>

  <!-- Subtle Resonance Wave Circles -->
  <circle cx="512" cy="512" r="410" fill="none" stroke="#00f2fe" stroke-opacity="0.16" stroke-width="3" stroke-dasharray="16 12"/>
  <circle cx="512" cy="512" r="460" fill="none" stroke="#ffd56b" stroke-opacity="0.10" stroke-width="2"/>

  <!-- Main Circular Emblem -->
  <circle cx="512" cy="512" r="330" fill="#0b1328" fill-opacity="0.85" stroke="url(#neonRingIcon)" stroke-width="12" filter="url(#iconGlow)"/>

  <!-- Inner Piano Keyboard -->
  <g clip-path="url(#circleClipIcon)">
    <!-- White Piano Keys -->
    <rect x="180" y="512" width="664" height="340" fill="#f2f7ff"/>

    <!-- Key Dividers -->
    <line x1="260" y1="512" x2="260" y2="840" stroke="#0e1730" stroke-width="5"/>
    <line x1="340" y1="512" x2="340" y2="840" stroke="#0e1730" stroke-width="5"/>
    <line x1="420" y1="512" x2="420" y2="840" stroke="#0e1730" stroke-width="5"/>
    <line x1="604" y1="512" x2="604" y2="840" stroke="#0e1730" stroke-width="5"/>
    <line x1="684" y1="512" x2="684" y2="840" stroke="#0e1730" stroke-width="5"/>
    <line x1="764" y1="512" x2="764" y2="840" stroke="#0e1730" stroke-width="5"/>

    <!-- Black Piano Keys -->
    <rect x="238" y="512" width="44" height="180" rx="8" fill="#090f20"/>
    <rect x="318" y="512" width="44" height="180" rx="8" fill="#090f20"/>
    <rect x="582" y="512" width="44" height="180" rx="8" fill="#090f20"/>
    <rect x="662" y="512" width="44" height="180" rx="8" fill="#090f20"/>
    <rect x="742" y="512" width="44" height="180" rx="8" fill="#090f20"/>
  </g>

  <!-- Horizontal Keybed Shelf -->
  <line x1="200" y1="512" x2="824" y2="512" stroke="url(#neonRingIcon)" stroke-width="8" stroke-linecap="round"/>

  <!-- Glowing Center Key Transitioning into Cross -->
  <rect x="477" y="160" width="70" height="640" rx="14" fill="url(#crossGradIcon)" filter="url(#iconGlow)"/>
  <rect x="372" y="300" width="280" height="70" rx="14" fill="url(#crossGradIcon)" filter="url(#iconGlow)"/>

  <!-- Brilliant Center Starburst Focal Point -->
  <circle cx="512" cy="335" r="14" fill="#ffffff" filter="url(#iconGlow)"/>
  <circle cx="512" cy="335" r="6" fill="#fffbe8"/>
</svg>'''

with open(os.path.join(artifact_dir, "piano_cross_v6_jewel.svg"), "w") as f:
    f.write(svg_jewel)

with open(os.path.join(artifact_dir, "piano_cross_v7_appicon.svg"), "w") as f:
    f.write(svg_appicon)

print("Saved jewel and appicon SVGs")
