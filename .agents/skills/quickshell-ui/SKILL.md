---
name: quickshell-ui
description: Quickshell UI consistency via the phi rounding scale, card clipping, and shared components. Use when adding or changing any visible shell surface, adjusting corner radius or the rounding setting, or adding shared components or settings rows.
---

# Quickshell UI

Every visible surface follows one corner scale derived from a single saved value. Match the scale; never invent radii. Style, imports, and naming follow CODING-STANDARDS.md. Settings rows and tabs follow components/settings/DOCS.md.

## Steps

Do these in order. Each step states how you know it is done.

1. **Read the scale.** `Settings.ui.rounding` (int, default 5) is the only saved value. `Settings.rounding.{lg,md,sm,xs}` derive from it by phi (1.618): lg is the value, each step down divides by phi and rounds. At default 5 that is 5/3/2/1.
   Done when you can name the four levels for the current setting without opening Settings.qml.

2. **Assign the level.** Lg for outer cards, popups, pills, and the settings shell. Md for one level in: tab highlights, device rows, stream cards, preview boxes, wallpaper thumbs, mid-size buttons. Sm for small controls: 28px icon buttons, preset chips, toggle thumbs, slider tracks. Xs for the tiniest outlines and dots.
   Done when every `radius:` in touched files names a scale level and no literal remains.

3. **Clip what bleeds.** A container whose children reach its edges (images, sidebar fills, wipe previews) becomes `ClippingRectangle` with `contentUnderBorder: true`. Plain `Rectangle` + `clip: true` leaves square corners poking through rounded borders. Simple cards stay `Rectangle` with `radius` + `clip: true`.
   Done when rounded containers show no square-corner poke at any rounding value including 0.

4. **Bind shared components once.** Toggle and Slider defaults come from the scale; delete per-call radius overrides except compact variants (stream thumbs pin Sm). New shared components take scale defaults the same way, so a rounding change propagates with no per-call edits.
   Done when moving the slider in Settings UI restyles every touched surface live.

5. **Verify.** `rg 'radius: 0'` over components/ is empty, `qs log` ends in Configuration Loaded, and kettshell.json still holds only `genie` + `rounding` under `ui`.
   Done when all three hold.

## Reference

### The scale

- lg: the saved value. Outer shells only.
- md: value / phi. First nesting level.
- sm: value / phi squared. Small controls.
- xs: value / phi cubed. Hairlines and dots.
- Zero stays zero at every level.

### Persistence guardrail

Declare derived values on the Settings root, beside the adapter, never inside the `ui` JsonObject. Every property inside that object is saved to kettshell.json and reloaded over its binding, so a derived value placed there freezes after one restart.
