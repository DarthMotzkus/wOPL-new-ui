# 07 — Theme layout

**Patches:** `customs/patches/theme_list.cfg.patch`,
`customs/patches/theme_coverflow.cfg.patch`
**Touches:** `misc/theme_list.cfg`, `misc/theme_coverflow.cfg`

## What it changes

Asset positions and layering for the two built-in views. Both files get the same structural
change plus per-view tuning.

### Structural change (both views)

Upstream draws `settings_bg` as the `Background` element. Here the `Background` becomes the
plasma pattern and `settings_bg` is re-declared right after it as a full-screen
`StaticImage`:

```
main0: { type = "Background";  pattern = "BG"; ... }
main1: { type = "StaticImage"; default = "settings_bg"; ... }
```

That is what puts the artwork *over* the animated plasma instead of replacing it, and it is
the other half of [05 — Settings background](05-settings-background.md). Every following
element is renumbered by one.

`plasma_blend_color = "#FFFFFF"` is removed from both files so the blend colour falls back
to the value set in [01 — Default colours](01-default-colors.md).

### List view (`theme_list.cfg`)

| Element | Change |
|---|---|
| `ItemsList` | `x=20 y=57 height=342` (was `40 / 38 / 380`) |
| `ItemCover` | `x=-61 y=-271`; apps cover `x=-61 y=-199` |
| `ItemIcon` (disc) | `x=-245 y=-195 wsX=-210`, reflection off |
| `MenuIcon` | `x=-11 y=348` |
| `ItemText` | added at `x=-94 y=-130` (and the apps variant), showing the game id |
| `lm_case_shadow` | removed |

### Coverflow view (`theme_coverflow.cfg`)

Reflections off on both `Coverflow` elements, everything after `main1` renumbered, the rest
of the geometry left as upstream.

## Why

Personal layout. The reference point is a known-good earlier build: these positions were
recovered from it and are treated as the source of truth whenever the layout drifts.

## Note on drift

Theme positions are the easiest thing in this fork to lose, because any refactor of the
patches silently re-orders elements. The authoritative final-state `.cfg` files are kept
outside this repository, in the local build tooling, together with a table of the canonical
positions. If the on-screen layout ever looks wrong, restore from those rather than
re-deriving from a running build.

## Upstreamable

No. Pure layout preference.

## How to revert

`git apply -R` either patch. They are independent of each other.
