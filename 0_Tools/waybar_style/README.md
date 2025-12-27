# Moondust Inspired Niri + Waybar Theme

My config files for a minimal, blue-gray color theme for [Niri](https://github.com/YaLTeR/niri), Waybar, Kitty, and so on, based on the amazing [Moondust theme](https://github.com/vanyauhalin/moondusttheme/) by Ivan Uhalin.

> [!NOTE]
> The Waybar statusbar is now rounded and translucent (see screenshot 1). If you prefer the 'flat' style, swap with the flat-config.jsonc and flat-style.css.

> [!IMPORTANT] 
> I'm new to Niri, and configuration like this in general. This setup is very much a work-in-progress and draws heavily from far more talented folks in the [Niri Setup Showcase](https://github.com/YaLTeR/niri/discussions/325). Contributions, suggestions, and PRs are welcome and encouraged. 

## Preview

<table>
  <tr>
    <td><img src="assets/screenshot_zen_rounded.png" alt="Moondust screenshot 1" width="320"></td>
    <td><img src="assets/screenshot_split.png" alt="Moondust screenshot 2" width="320"></td>
    <td><img src="assets/screenshot_fuzzel.png" alt="Moondust screenshot 3" width="320"></td>
  </tr>
</table>

## Configs

This repository includes my Moondust-styled configurations for:

- Fastfetch (system info display)
- Fish (shell + Fisher theme)
- Fuzzel (application launcher)
- Kitty (terminal emulator)
- Mako (notifications)
- Niri (Wayland tiling compositor)
- Starship (prompt)
- Sublime Text (editor, themed)
- Waybar (status bar)

## Color Palette

### Dark Theme

#### Background

| Name | Hex | Preview |
|------|-----|---------|
| **Background** | `#161A1D` | ![#161A1D](https://img.shields.io/badge/161A1D-161A1D?style=flat-square) |

*Editor/terminal background*

#### Gray

| Index | Hex | Preview |
|-------|-----|---------|
| **0** | `#D2D4D5` | ![#D2D4D5](https://img.shields.io/badge/D2D4D5-D2D4D5?style=flat-square) |
| **1** | `#B1B6B9` | ![#B1B6B9](https://img.shields.io/badge/B1B6B9-B1B6B9?style=flat-square) |
| **2** | `#89949A` | ![#89949A](https://img.shields.io/badge/89949A-89949A?style=flat-square) |
| **3** | `#637179` | ![#637179](https://img.shields.io/badge/637179-637179?style=flat-square) |
| **4** | `#455259` | ![#455259](https://img.shields.io/badge/455259-455259?style=flat-square) |
| **5** | `#343F46` | ![#343F46](https://img.shields.io/badge/343F46-343F46?style=flat-square) |
| **6** | `#2C343A` | ![#2C343A](https://img.shields.io/badge/2C343A-2C343A?style=flat-square) |
| **7** | `#262C31` | ![#262C31](https://img.shields.io/badge/262C31-262C31?style=flat-square) |
| **8** | `#22272B` | ![#22272B](https://img.shields.io/badge/22272B-22272B?style=flat-square) |
| **9** | `#1E2225` | ![#1E2225](https://img.shields.io/badge/1E2225-1E2225?style=flat-square) |

*Neutral grays from brightest (0) to darkest (9)*

#### Slate

| Index | Hex | Preview |
|-------|-----|---------|
| **0** | `#B2D0EB` | ![#B2D0EB](https://img.shields.io/badge/B2D0EB-B2D0EB?style=flat-square) |
| **1** | `#8FAFCC` | ![#8FAFCC](https://img.shields.io/badge/8FAFCC-8FAFCC?style=flat-square) |
| **2** | `#6885A1` | ![#6885A1](https://img.shields.io/badge/6885A1-6885A1?style=flat-square) |
| **3** | `#4D6680` | ![#4D6680](https://img.shields.io/badge/4D6680-4D6680?style=flat-square) |
| **4** | `#3C5167` | ![#3C5167](https://img.shields.io/badge/3C5167-3C5167?style=flat-square) |
| **5** | `#304255` | ![#304255](https://img.shields.io/badge/304255-304255?style=flat-square) |
| **6** | `#273545` | ![#273545](https://img.shields.io/badge/273545-273545?style=flat-square) |
| **7** | `#222D39` | ![#222D39](https://img.shields.io/badge/222D39-222D39?style=flat-square) |
| **8** | `#1F262E` | ![#1F262E](https://img.shields.io/badge/1F262E-1F262E?style=flat-square) |
| **9** | `#1E2329` | ![#1E2329](https://img.shields.io/badge/1E2329-1E2329?style=flat-square) |

*Blue-gray tones from brightest (0) to darkest (9)*

#### Blue

| Index | Hex | Preview |
|-------|-----|---------|
| **0** | `#4D8FDB` | ![#4D8FDB](https://img.shields.io/badge/4D8FDB-4D8FDB?style=flat-square) |
| **1** | `#3A82CF` | ![#3A82CF](https://img.shields.io/badge/3A82CF-3A82CF?style=flat-square) |
| **2** | `#2C75C3` | ![#2C75C3](https://img.shields.io/badge/2C75C3-2C75C3?style=flat-square) |
| **3** | `#2769B4` | ![#2769B4](https://img.shields.io/badge/2769B4-2769B4?style=flat-square) |
| **4** | `#235D9F` | ![#235D9F](https://img.shields.io/badge/235D9F-235D9F?style=flat-square) |
| **5** | `#1C4C82` | ![#1C4C82](https://img.shields.io/badge/1C4C82-1C4C82?style=flat-square) |
| **6** | `#173E6E` | ![#173E6E](https://img.shields.io/badge/173E6E-173E6E?style=flat-square) |
| **7** | `#133358` | ![#133358](https://img.shields.io/badge/133358-133358?style=flat-square) |
| **8** | `#112945` | ![#112945](https://img.shields.io/badge/112945-112945?style=flat-square) |
| **9** | `#10243C` | ![#10243C](https://img.shields.io/badge/10243C-10243C?style=flat-square) |

*Accent blues from brightest (0) to darkest (9)*

### Non-Canonical Colors

These colors are used for specific UI purposes but are not part of the canonical Moondust palette:

| Name | Hex | Preview | Usage |
|------|-----|---------|-------|
| **Warning** | `#E8B87E` | ![#E8B87E](https://img.shields.io/badge/E8B87E-E8B87E?style=flat-square) | Warning states (Mako only) |
| **Critical** | `#E67C7C` | ![#E67C7C](https://img.shields.io/badge/E67C7C-E67C7C?style=flat-square) | Critical/error states, power button |

## Quick Reference

### Common UI Elements
| Element | Color | Hex | Preview |
|---------|-------|-----|---------|
| Background | Background | `#161A1D` | ![#161A1D](https://img.shields.io/badge/161A1D-161A1D?style=flat-square) |
| Foreground | Gray 1 | `#B1B6B9` | ![#B1B6B9](https://img.shields.io/badge/B1B6B9-B1B6B9?style=flat-square) |
| Selection | Blue 2 | `#2C75C3` | ![#2C75C3](https://img.shields.io/badge/2C75C3-2C75C3?style=flat-square) |
| Border | Gray 5 | `#343F46` | ![#343F46](https://img.shields.io/badge/343F46-343F46?style=flat-square) |
| Link/Hover | Blue 0 | `#4D8FDB` | ![#4D8FDB](https://img.shields.io/badge/4D8FDB-4D8FDB?style=flat-square) |
| Comment | Gray 3 | `#637179` | ![#637179](https://img.shields.io/badge/637179-637179?style=flat-square) |

### Syntax Colors
| Element | Color | Hex | Preview |
|---------|-------|-----|---------|
| Keywords | Gray 2 | `#89949A` | ![#89949A](https://img.shields.io/badge/89949A-89949A?style=flat-square) |
| Text/Variables | Gray 1 | `#B1B6B9` | ![#B1B6B9](https://img.shields.io/badge/B1B6B9-B1B6B9?style=flat-square) |
| Strings | Slate 1 | `#8FAFCC` | ![#8FAFCC](https://img.shields.io/badge/8FAFCC-8FAFCC?style=flat-square) |
| String Quotes | Slate 2 | `#6885A1` | ![#6885A1](https://img.shields.io/badge/6885A1-6885A1?style=flat-square) |
| Comments | Gray 3 | `#637179` | ![#637179](https://img.shields.io/badge/637179-637179?style=flat-square) |

## Resources

- [Official Moondust Theme](https://moondustthe.me/)
- [VS Code Theme](https://marketplace.visualstudio.com/items?itemName=vanyauhalin.moondusttheme)
- [Color Definitions](https://github.com/vanyauhalin/moondusttheme/blob/main/lib/colors.js)

## License

Based on Moondust by Ivan Uhalin (MIT License)