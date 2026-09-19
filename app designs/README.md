# Worship Companion – Brand Identity & Adaptive Icon Design System

This directory contains the complete design assets for **Worship Companion**, engineered to strictly follow **Apple Human Interface Guidelines (HIG)** and **Google Material Design 3 (Material You)** adaptive icon specifications.

---

## Directory Structure

```
app designs/
├── logo/
│   ├── worship_companion_logo_dark.svg          # Master vector logo with dark card container
│   ├── worship_companion_logo_dark.png          # 1024x1024 rasterized logo
│   ├── worship_companion_logo_transparent.svg  # Transparent vector for web headers & print
│   └── worship_companion_logo_transparent.png  # Transparent rasterized logo
├── android/
│   ├── adaptive_layers/
│   │   ├── ic_launcher_background.svg           # Full-bleed 108dp canvas background layer
│   │   ├── ic_launcher_background.png           # 1024x1024 background layer
│   │   ├── ic_launcher_foreground.svg           # Strict 66% safe zone foreground emblem
│   │   ├── ic_launcher_foreground.png           # 1024x1024 foreground layer
│   │   ├── ic_launcher_monochrome.svg           # Material You Dynamic Themed silhouette
│   │   └── ic_launcher_monochrome.png           # Material You Dynamic Themed PNG
│   ├── preview_shapes/
│   │   ├── pixel_ui_circle_preview.png          # Google Pixel UI launcher preview
│   │   ├── samsung_oneui_squircle_preview.png   # Samsung One UI launcher preview
│   │   └── material_you_themed_preview.png      # Android 13/14+ wallpaper-adaptive preview
│   └── res/
│       ├── mipmap-anydpi-v26/
│       │   ├── ic_launcher.xml                  # Adaptive icon definition (bg, fg, mono)
│       │   └── ic_launcher_round.xml            # Round adaptive icon definition
│       ├── mipmap-mdpi/                         # 48x48 launcher / 108x108 layers
│       ├── mipmap-hdpi/                         # 72x72 launcher / 162x162 layers
│       ├── mipmap-xhdpi/                        # 96x96 launcher / 216x216 layers
│       ├── mipmap-xxhdpi/                       # 144x144 launcher / 324x324 layers
│       └── mipmap-xxxhdpi/                      # 192x192 launcher / 432x432 layers
└── ios/
    ├── AppIcon-1024.svg                         # Master 1024x1024 Apple Liquid Glass icon
    ├── AppIcon-1024.png                         # 1024x1024 master icon for App Store & Xcode
    ├── AppIcon-1024-dark.svg                    # iOS 18 Dark Mode icon variant
    ├── AppIcon-1024-dark.png                    # iOS 18 Dark Mode icon raster
    └── preview/
        └── ios_home_screen_preview.png          # iOS Home Screen squircle preview
```

---

## Design Specifications & Compliance

### 1. The Emblem Metaphor
- **Piano Keys to Cross**: The lower keyboard represents worship and music, with the center black key rising organically into the Christian cross.
- **Harmonious Transition**: The cross stem terminates flush with the adjacent black keys, eliminating awkward elongation.
- **Seamless Intersection**: The cross intersection is clean and solid—no center bolts or artificial pins.
- **Acoustic Waves**: Concentric frequency rings surround the emblem to evoke acoustic resonance.

### 2. Google Material Design 3 (Android Adaptive Standard)
- **108dp x 108dp Canvas**: The icon is separated into three independent layers.
- **Strict 66% Safe Zone**: The central 72dp diameter (66.67% of the canvas) contains the entire emblem. Even when OEM launchers apply aggressive masks, nothing is ever clipped:
  - **Google Pixel UI**: Masked to a circle (72dp diameter).
  - **Samsung One UI**: Masked to a continuous squircle.
  - **Motorola / Nothing OS / Xiaomi**: Masked to teardrops or rounded rectangles.
- **Material You Dynamic Theming**: Android 13+ automatically extracts colors from the user's wallpaper and applies them to the `ic_launcher_monochrome` layer for a personalized, unified theme.

### 3. Apple Human Interface Guidelines (iOS Standards)
- **1024x1024 Full Bleed Square**: Apple requires flat square images without pre-cut rounded corners; iOS automatically applies the 22.37% continuous squircle curvature.
- **Liquid Glass Sheen**: Frosted glass highlight across the top facet, specular edge reflections, and ambient depth lighting.
- **iOS 18 Dark Variant**: Pure obsidian dark theme (`#000000` base) with luminous electric cyan and mint accents.
