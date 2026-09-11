---
name: quickshell-ui
description: Quickshell UI consistency via the phi rounding scale, card clipping, shared components, and type rules. Use when adding or changing any visible shell surface, adjusting corner radius or the rounding setting, adding shared components or settings rows, or touching fonts or text.
---

# Quickshell UI

Every visible surface follows one corner scale derived from a single saved value. Match the scale; never invent radii. Every text element follows the three type categories under Type. Style, imports, and naming follow CODING-STANDARDS.md. Settings rows and tabs follow components/settings/DOCS.md. Where those files conflict with this skill, they win.

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

5. **Set type by category.** Body and headings take the sans family, clocks and percentages take mono, glyphs take icons. Set family and pixelSize from Typography and weight on the item, never by overriding a bound grouped font. Prefer Label once it exists.
   Done when every touched Text follows the override rule and its weight matches its place in the hierarchy.

6. **Verify.** `rg 'radius: 0'` over components/ is empty, no touched Text pairs `font: Typography.x` with a `font.*` override on the same item, `qs log` ends in Configuration Loaded, and kettshell.json still holds only its known keys under `ui`.
   Done when all four hold.

## Reference

### The scale

- lg: the saved value. Outer shells only.
- md: value / phi. First nesting level.
- sm: value / phi squared. Small controls.
- xs: value / phi cubed. Hairlines and dots.
- Zero stays zero at every level.

### Persistence guardrail

Declare derived values on the Settings root, beside the adapter, never inside the `ui` JsonObject. Every property inside that object is saved to kettshell.json and reloaded over its binding, so a derived value placed there freezes after one restart.

## Type

### Categories

Three families, ever. Sans for nearly everything. Mono where characters must align: clocks, percentages, numeric columns. Icons for glyphs only, never mixed with text sizing logic. No serif; it reads traditional and has no place in a shell.

### Singleton shape

`theme/Typography.qml` holds one `readonly property font` per category, all `Font.Normal`:

```qml
readonly property font sans: Qt.font({
  family: "SF Pro Text",
  pixelSize: 13,
  weight: Font.Normal
})
```

Weight is a per-use override, never a separate property, so there is no `sansBold`. Size comes from the scale below, not the font object.

### The override rule

Binding a whole grouped `font` then overriding a sub-property gets clobbered by evaluation order. Pull the pieces individually and set weight on the item:

```qml
Text {
  font.family: Typography.sans.family
  font.pixelSize: Typography.sans.pixelSize
  font.weight: Font.Bold
}
```

Demand: every Text you touch sets its font pieces individually or uses Label. Never pair `font: Typography.x` with a `font.*` override on the same item.

### Weight and size

Headings and buttons take `Font.DemiBold` to `Font.Bold`; body stays `Font.Normal`; captions take `Font.Normal` or `Font.Medium`. Mono usually offers only normal and bold. Sizes hang off one persisted base, `Settings.fontScale`, tuned in the Fonts tab: `sizeXS` is base * 0.85, `sizeSM` is base, `sizeMD` is base * 1.15, `sizeLG` is base * 1.4. Bigger text runs tighter leading and tracking; smaller text runs more generous.

### Label

`components/shared/Label.qml` sits beside Slider and Toggle and exposes `useMono`, `size`, and `weight`, assembling the font internally so call sites shrink to one or two lines. The source of truth stays in Typography.

### Picks and contrast

Sans is SF Pro Text, mono defaults to JetBrains Mono (JetBrains Mono and IBM Plex Mono are both freely redistributable; SF Mono licensing excludes non-Apple apps), both user-overridable from the Fonts tab, icons stay Phosphor. Small text holds 7:1 contrast against its background. Treat a new color in Colors.qml and a new size in Typography.qml as one paired decision, not two.


