import os
import subprocess

artifact_dir = "/Users/reyzie29/.gemini/antigravity-ide/brain/04d35cd7-a681-40a1-9d4b-726634c421f7"
os.makedirs(artifact_dir, exist_ok=True)

# -------------------------------------------------------------
# Concept 1: Electric Celestial (Cyan & Gold Glow on Midnight Navy)
# -------------------------------------------------------------
svg1 = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 850" width="800" height="850">
  <defs>
    <radialGradient id="bgGrad1" cx="50%" cy="35%" r="65%">
      <stop offset="0%" stop-color="#142145"/>
      <stop offset="60%" stop-color="#090e1f"/>
      <stop offset="100%" stop-color="#04060c"/>
    </radialGradient>
    <radialGradient id="crossGlow1" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="#ffd56b" stop-opacity="0.6"/>
      <stop offset="40%" stop-color="#4facfe" stop-opacity="0.3"/>
      <stop offset="100%" stop-color="#00f2fe" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="circleStroke1" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#00f2fe"/>
      <stop offset="50%" stop-color="#4facfe"/>
      <stop offset="100%" stop-color="#ffd56b"/>
    </linearGradient>
    <linearGradient id="crossGrad1" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#fff8e7"/>
      <stop offset="30%" stop-color="#ffd257"/>
      <stop offset="70%" stop-color="#00f2fe"/>
      <stop offset="100%" stop-color="#0b54d6"/>
    </linearGradient>
    <linearGradient id="textGrad1" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#ffffff"/>
      <stop offset="70%" stop-color="#d4e6ff"/>
      <stop offset="100%" stop-color="#ffd56b"/>
    </linearGradient>
    <filter id="glow1" x="-30%" y="-30%" width="160%" height="160%">
      <feGaussianBlur stdDeviation="8" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
    <clipPath id="circleClip1">
      <circle cx="400" cy="330" r="148"/>
    </clipPath>
  </defs>

  <!-- Background App Card / Squircle -->
  <rect x="20" y="20" width="760" height="810" rx="120" fill="url(#bgGrad1)" stroke="#1e2e5c" stroke-width="2"/>

  <!-- Halo Aura Behind Cross -->
  <circle cx="400" cy="205" r="130" fill="url(#crossGlow1)"/>
  
  <!-- Subtle Resonance Waves -->
  <circle cx="400" cy="330" r="185" fill="none" stroke="#00f2fe" stroke-opacity="0.15" stroke-width="2" stroke-dasharray="8 6"/>
  <circle cx="400" cy="330" r="215" fill="none" stroke="#ffd257" stroke-opacity="0.08" stroke-width="1.5"/>

  <!-- Main Circle Outer Ring -->
  <circle cx="400" cy="330" r="150" fill="#0c152c" fill-opacity="0.8" stroke="url(#circleStroke1)" stroke-width="6" filter="url(#glow1)"/>

  <!-- Content Inside Circle -->
  <g clip-path="url(#circleClip1)">
    <!-- White Piano Keys Background (Lower Half) -->
    <rect x="230" y="330" width="340" height="160" fill="#eef5ff"/>
    
    <!-- White Key Vertical Dividers -->
    <line x1="280" y1="330" x2="280" y2="480" stroke="#0d1833" stroke-width="3"/>
    <line x1="320" y1="330" x2="320" y2="480" stroke="#0d1833" stroke-width="3"/>
    <line x1="360" y1="330" x2="360" y2="480" stroke="#0d1833" stroke-width="3"/>
    <line x1="440" y1="330" x2="440" y2="480" stroke="#0d1833" stroke-width="3"/>
    <line x1="480" y1="330" x2="480" y2="480" stroke="#0d1833" stroke-width="3"/>
    <line x1="520" y1="330" x2="520" y2="480" stroke="#0d1833" stroke-width="3"/>

    <!-- Black Piano Keys Left & Right -->
    <rect x="268" y="330" width="24" height="85" rx="5" fill="#091024"/>
    <rect x="308" y="330" width="24" height="85" rx="5" fill="#091024"/>
    <rect x="428" y="330" width="24" height="85" rx="5" fill="#091024"/>
    <rect x="468" y="330" width="24" height="85" rx="5" fill="#091024"/>
    <rect x="508" y="330" width="24" height="85" rx="5" fill="#091024"/>
  </g>

  <!-- Horizontal Keybed Shelf -->
  <line x1="250" y1="330" x2="550" y2="330" stroke="#00f2fe" stroke-width="4" stroke-linecap="round"/>

  <!-- Center Key Extending Into Glowing Cross -->
  <!-- Vertical Cross Stem -->
  <rect x="382" y="115" width="36" height="340" rx="8" fill="url(#crossGrad1)" filter="url(#glow1)"/>
  <!-- Horizontal Cross Bar -->
  <rect x="325" y="185" width="150" height="36" rx="8" fill="url(#crossGrad1)" filter="url(#glow1)"/>

  <!-- Cross Center Star Highlight -->
  <circle cx="400" cy="203" r="8" fill="#ffffff" filter="url(#glow1)"/>

  <!-- Typography -->
  <text x="400" y="605" text-anchor="middle" font-family="-apple-system, BlinkMacSystemFont, 'Plus Jakarta Sans', Inter, sans-serif" font-size="46" font-weight="800" letter-spacing="10" fill="url(#textGrad1)">WORSHIP</text>
  <text x="400" y="660" text-anchor="middle" font-family="-apple-system, BlinkMacSystemFont, 'Plus Jakarta Sans', Inter, sans-serif" font-size="28" font-weight="600" letter-spacing="16" fill="#7fa5ff">COMPANION</text>
  
  <!-- Subtle Tagline / Decorative Accents -->
  <line x1="300" y1="705" x2="370" y2="705" stroke="#4facfe" stroke-opacity="0.4" stroke-width="2"/>
  <circle cx="400" cy="705" r="3.5" fill="#ffd257"/>
  <line x1="430" y1="705" x2="500" y2="705" stroke="#4facfe" stroke-opacity="0.4" stroke-width="2"/>
</svg>'''

# -------------------------------------------------------------
# Concept 2: Royal Gold & Imperial Sapphire (Regal, Luxury & Sacred)
# -------------------------------------------------------------
svg2 = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 850" width="800" height="850">
  <defs>
    <radialGradient id="bgGrad2" cx="50%" cy="30%" r="70%">
      <stop offset="0%" stop-color="#121b33"/>
      <stop offset="70%" stop-color="#090d1a"/>
      <stop offset="100%" stop-color="#04060a"/>
    </radialGradient>
    <linearGradient id="goldGrad2" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#ffe999"/>
      <stop offset="25%" stop-color="#d4af37"/>
      <stop offset="50%" stop-color="#fff3b8"/>
      <stop offset="75%" stop-color="#aa801e"/>
      <stop offset="100%" stop-color="#e8c257"/>
    </linearGradient>
    <linearGradient id="silverKeyGrad2" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#fdfbf7"/>
      <stop offset="100%" stop-color="#e3ded5"/>
    </linearGradient>
    <radialGradient id="goldHalo2" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="#ffd56b" stop-opacity="0.4"/>
      <stop offset="50%" stop-color="#d4af37" stop-opacity="0.15"/>
      <stop offset="100%" stop-color="#d4af37" stop-opacity="0"/>
    </radialGradient>
    <filter id="goldShadow2" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="6" stdDeviation="10" flood-color="#ffd56b" flood-opacity="0.3"/>
    </filter>
    <clipPath id="circleClip2">
      <circle cx="400" cy="330" r="148"/>
    </clipPath>
  </defs>

  <!-- Background App Card -->
  <rect x="20" y="20" width="760" height="810" rx="120" fill="url(#bgGrad2)" stroke="url(#goldGrad2)" stroke-width="1.5" stroke-opacity="0.4"/>

  <!-- Halo Aura Behind Cross -->
  <circle cx="400" cy="205" r="140" fill="url(#goldHalo2)"/>

  <!-- Main Circle Outer Ring with Metallic Gold Rim -->
  <circle cx="400" cy="330" r="150" fill="#0f172e" stroke="url(#goldGrad2)" stroke-width="7" filter="url(#goldShadow2)"/>

  <!-- Content Inside Circle -->
  <g clip-path="url(#circleClip2)">
    <!-- Ivory Piano Keys Background -->
    <rect x="230" y="330" width="340" height="160" fill="url(#silverKeyGrad2)"/>
    
    <!-- White Key Dividers in Gold Inlay -->
    <line x1="280" y1="330" x2="280" y2="480" stroke="#121b33" stroke-width="3"/>
    <line x1="320" y1="330" x2="320" y2="480" stroke="#121b33" stroke-width="3"/>
    <line x1="360" y1="330" x2="360" y2="480" stroke="#121b33" stroke-width="3"/>
    <line x1="440" y1="330" x2="440" y2="480" stroke="#121b33" stroke-width="3"/>
    <line x1="480" y1="330" x2="480" y2="480" stroke="#121b33" stroke-width="3"/>
    <line x1="520" y1="330" x2="520" y2="480" stroke="#121b33" stroke-width="3"/>

    <!-- Black Piano Keys in Obsidian with Gold Bevel -->
    <rect x="268" y="330" width="24" height="88" rx="4" fill="#0b0f1a" stroke="url(#goldGrad2)" stroke-width="1"/>
    <rect x="308" y="330" width="24" height="88" rx="4" fill="#0b0f1a" stroke="url(#goldGrad2)" stroke-width="1"/>
    <rect x="428" y="330" width="24" height="88" rx="4" fill="#0b0f1a" stroke="url(#goldGrad2)" stroke-width="1"/>
    <rect x="468" y="330" width="24" height="88" rx="4" fill="#0b0f1a" stroke="url(#goldGrad2)" stroke-width="1"/>
    <rect x="508" y="330" width="24" height="88" rx="4" fill="#0b0f1a" stroke="url(#goldGrad2)" stroke-width="1"/>
  </g>

  <!-- Horizontal Keybed Rim in Brushed Gold -->
  <line x1="250" y1="330" x2="550" y2="330" stroke="url(#goldGrad2)" stroke-width="5" stroke-linecap="round"/>

  <!-- Sculpted Golden Cross -->
  <!-- Vertical Cross Stem -->
  <rect x="381" y="110" width="38" height="340" rx="6" fill="url(#goldGrad2)" filter="url(#goldShadow2)"/>
  <!-- Horizontal Cross Bar -->
  <rect x="320" y="182" width="160" height="38" rx="6" fill="url(#goldGrad2)" filter="url(#goldShadow2)"/>

  <!-- Cross Center Diamond Facet Detail -->
  <polygon points="400,188 412,201 400,214 388,201" fill="#ffffff" opacity="0.85"/>

  <!-- Typography in Regal Gold -->
  <text x="400" y="605" text-anchor="middle" font-family="Georgia, 'Cinzel', -apple-system, serif" font-size="44" font-weight="700" letter-spacing="12" fill="url(#goldGrad2)">WORSHIP</text>
  <text x="400" y="660" text-anchor="middle" font-family="-apple-system, BlinkMacSystemFont, 'Plus Jakarta Sans', sans-serif" font-size="26" font-weight="600" letter-spacing="18" fill="#d4c19c">COMPANION</text>

  <!-- Decorative Gold Filigree Divider -->
  <line x1="280" y1="705" x2="380" y2="705" stroke="url(#goldGrad2)" stroke-width="1.5" stroke-opacity="0.6"/>
  <polygon points="400,701 404,705 400,709 396,705" fill="url(#goldGrad2)"/>
  <line x1="420" y1="705" x2="520" y2="705" stroke="url(#goldGrad2)" stroke-width="1.5" stroke-opacity="0.6"/>
</svg>'''

# -------------------------------------------------------------
# Concept 3: Sunset Horizon & Acoustic Wave (Warm, Inspiring & Uplifting)
# -------------------------------------------------------------
svg3 = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 850" width="800" height="850">
  <defs>
    <radialGradient id="bgGrad3" cx="50%" cy="30%" r="75%">
      <stop offset="0%" stop-color="#2d1547"/>
      <stop offset="50%" stop-color="#150d2e"/>
      <stop offset="100%" stop-color="#080414"/>
    </radialGradient>
    <radialGradient id="sunsetAura3" cx="50%" cy="45%" r="55%">
      <stop offset="0%" stop-color="#ff9900" stop-opacity="0.7"/>
      <stop offset="35%" stop-color="#ff4b72" stop-opacity="0.4"/>
      <stop offset="70%" stop-color="#7928ca" stop-opacity="0.2"/>
      <stop offset="100%" stop-color="#000000" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="sunsetGrad3" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#ffbe0b"/>
      <stop offset="35%" stop-color="#fb5607"/>
      <stop offset="70%" stop-color="#ff006e"/>
      <stop offset="100%" stop-color="#8338ec"/>
    </linearGradient>
    <linearGradient id="crossSunsetGrad3" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#fff5cc"/>
      <stop offset="25%" stop-color="#ffbe0b"/>
      <stop offset="60%" stop-color="#ff006e"/>
      <stop offset="100%" stop-color="#3a0ca3"/>
    </linearGradient>
    <filter id="warmGlow3" x="-20%" y="-20%" width="140%" height="140%">
      <feGaussianBlur stdDeviation="8" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
    <clipPath id="circleClip3">
      <circle cx="400" cy="330" r="148"/>
    </clipPath>
  </defs>

  <!-- Background App Card -->
  <rect x="20" y="20" width="760" height="810" rx="120" fill="url(#bgGrad3)" stroke="#451e6b" stroke-width="2"/>

  <!-- Sunset Radiance Behind Cross -->
  <circle cx="400" cy="230" r="160" fill="url(#sunsetAura3)"/>

  <!-- Dynamic Ring with Sunset Gradient -->
  <circle cx="400" cy="330" r="150" fill="#140c2b" fill-opacity="0.85" stroke="url(#sunsetGrad3)" stroke-width="6" filter="url(#warmGlow3)"/>

  <!-- Content Inside Circle -->
  <g clip-path="url(#circleClip3)">
    <!-- Warm White Piano Keys Background -->
    <rect x="230" y="330" width="340" height="160" fill="#fff6ec"/>
    
    <!-- Key Dividers -->
    <line x1="280" y1="330" x2="280" y2="480" stroke="#231238" stroke-width="3"/>
    <line x1="320" y1="330" x2="320" y2="480" stroke="#231238" stroke-width="3"/>
    <line x1="360" y1="330" x2="360" y2="480" stroke="#231238" stroke-width="3"/>
    <line x1="440" y1="330" x2="440" y2="480" stroke="#231238" stroke-width="3"/>
    <line x1="480" y1="330" x2="480" y2="480" stroke="#231238" stroke-width="3"/>
    <line x1="520" y1="330" x2="520" y2="480" stroke="#231238" stroke-width="3"/>

    <!-- Black Piano Keys with Sunset Hue -->
    <rect x="268" y="330" width="24" height="86" rx="4" fill="#1c0b30"/>
    <rect x="308" y="330" width="24" height="86" rx="4" fill="#1c0b30"/>
    <rect x="428" y="330" width="24" height="86" rx="4" fill="#1c0b30"/>
    <rect x="468" y="330" width="24" height="86" rx="4" fill="#1c0b30"/>
    <rect x="508" y="330" width="24" height="86" rx="4" fill="#1c0b30"/>
  </g>

  <!-- Horizontal Sunset Divider -->
  <line x1="250" y1="330" x2="550" y2="330" stroke="url(#sunsetGrad3)" stroke-width="4" stroke-linecap="round"/>

  <!-- Radiant Cross -->
  <rect x="382" y="112" width="36" height="340" rx="8" fill="url(#crossSunsetGrad3)" filter="url(#warmGlow3)"/>
  <rect x="325" y="182" width="150" height="36" rx="8" fill="url(#crossSunsetGrad3)" filter="url(#warmGlow3)"/>

  <!-- Glowing Sun Sparkle At Intersection -->
  <circle cx="400" cy="200" r="10" fill="#fff9e6" filter="url(#warmGlow3)"/>

  <!-- Typography -->
  <text x="400" y="605" text-anchor="middle" font-family="-apple-system, BlinkMacSystemFont, 'Plus Jakarta Sans', Inter, sans-serif" font-size="46" font-weight="800" letter-spacing="10" fill="#ffffff">WORSHIP</text>
  <text x="400" y="660" text-anchor="middle" font-family="-apple-system, BlinkMacSystemFont, 'Plus Jakarta Sans', Inter, sans-serif" font-size="28" font-weight="600" letter-spacing="16" fill="#ff70a6">COMPANION</text>

  <!-- Subtle Accent -->
  <circle cx="340" cy="705" r="3" fill="#ffbe0b"/>
  <circle cx="400" cy="705" r="4" fill="#ff006e"/>
  <circle cx="460" cy="705" r="3" fill="#8338ec"/>
</svg>'''

# -------------------------------------------------------------
# Concept 4: Prismatic Modernist / Equalizer Keys & Cross (Apple Design Award)
# -------------------------------------------------------------
svg4 = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 850" width="800" height="850">
  <defs>
    <radialGradient id="bgGrad4" cx="50%" cy="30%" r="70%">
      <stop offset="0%" stop-color="#131929"/>
      <stop offset="60%" stop-color="#0a0d17"/>
      <stop offset="100%" stop-color="#040508"/>
    </radialGradient>
    <linearGradient id="prismGrad4" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#00f2fe"/>
      <stop offset="30%" stop-color="#4facfe"/>
      <stop offset="70%" stop-color="#6b11ff"/>
      <stop offset="100%" stop-color="#ff0844"/>
    </linearGradient>
    <linearGradient id="whiteKeyGrad4" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#ffffff"/>
      <stop offset="100%" stop-color="#dce6f5"/>
    </linearGradient>
    <linearGradient id="crossPrism4" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#00f2fe"/>
      <stop offset="50%" stop-color="#4facfe"/>
      <stop offset="100%" stop-color="#6b11ff"/>
    </linearGradient>
    <filter id="softGlow4" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="8" stdDeviation="12" flood-color="#4facfe" flood-opacity="0.35"/>
    </filter>
    <clipPath id="circleClip4">
      <circle cx="400" cy="330" r="148"/>
    </clipPath>
  </defs>

  <!-- Background App Card -->
  <rect x="20" y="20" width="760" height="810" rx="120" fill="url(#bgGrad4)" stroke="#1a243d" stroke-width="2"/>

  <!-- Minimal Outer Ring with Prismatic Gradient -->
  <circle cx="400" cy="330" r="150" fill="#0d1424" fill-opacity="0.9" stroke="url(#prismGrad4)" stroke-width="5" filter="url(#softGlow4)"/>

  <!-- Content Inside Circle -->
  <g clip-path="url(#circleClip4)">
    <!-- Pristine White Keys -->
    <rect x="230" y="330" width="340" height="160" fill="url(#whiteKeyGrad4)"/>
    
    <!-- Fine Key Dividers -->
    <line x1="280" y1="330" x2="280" y2="480" stroke="#0a0e1a" stroke-width="2.5"/>
    <line x1="320" y1="330" x2="320" y2="480" stroke="#0a0e1a" stroke-width="2.5"/>
    <line x1="360" y1="330" x2="360" y2="480" stroke="#0a0e1a" stroke-width="2.5"/>
    <line x1="440" y1="330" x2="440" y2="480" stroke="#0a0e1a" stroke-width="2.5"/>
    <line x1="480" y1="330" x2="480" y2="480" stroke="#0a0e1a" stroke-width="2.5"/>
    <line x1="520" y1="330" x2="520" y2="480" stroke="#0a0e1a" stroke-width="2.5"/>

    <!-- Black Piano Keys with Glossy Finish -->
    <rect x="268" y="330" width="24" height="84" rx="4" fill="#0c101d"/>
    <rect x="308" y="330" width="24" height="84" rx="4" fill="#0c101d"/>
    <rect x="428" y="330" width="24" height="84" rx="4" fill="#0c101d"/>
    <rect x="468" y="330" width="24" height="84" rx="4" fill="#0c101d"/>
    <rect x="508" y="330" width="24" height="84" rx="4" fill="#0c101d"/>
  </g>

  <!-- Horizontal Keybed Rim -->
  <line x1="250" y1="330" x2="550" y2="330" stroke="url(#prismGrad4)" stroke-width="4.5" stroke-linecap="round"/>

  <!-- Elegant Modernist Cross with Prismatic Gradient -->
  <rect x="383" y="115" width="34" height="340" rx="8" fill="url(#crossPrism4)" filter="url(#softGlow4)"/>
  <rect x="328" y="185" width="144" height="34" rx="8" fill="url(#crossPrism4)" filter="url(#softGlow4)"/>

  <!-- Center Focal Core Light -->
  <circle cx="400" cy="202" r="7" fill="#ffffff"/>

  <!-- Clean Swiss-Style Typography -->
  <text x="400" y="605" text-anchor="middle" font-family="-apple-system, BlinkMacSystemFont, 'Inter', 'Plus Jakarta Sans', sans-serif" font-size="44" font-weight="800" letter-spacing="11" fill="#ffffff">WORSHIP</text>
  <text x="400" y="660" text-anchor="middle" font-family="-apple-system, BlinkMacSystemFont, 'Inter', 'Plus Jakarta Sans', sans-serif" font-size="28" font-weight="500" letter-spacing="18" fill="#4facfe">COMPANION</text>

  <!-- Minimal Linear Accents -->
  <line x1="320" y1="705" x2="480" y2="705" stroke="url(#prismGrad4)" stroke-width="2" stroke-linecap="round"/>
</svg>'''

files = [
    ("piano_cross_v1_celestial.svg", svg1),
    ("piano_cross_v2_royal_gold.svg", svg2),
    ("piano_cross_v3_sunset.svg", svg3),
    ("piano_cross_v4_prismatic.svg", svg4),
]

for fname, content in files:
    path = os.path.join(artifact_dir, fname)
    with open(path, "w") as f:
        f.write(content)
    print(f"Saved {path}")
