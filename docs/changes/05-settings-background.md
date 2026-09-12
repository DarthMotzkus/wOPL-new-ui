# 05 — Settings background

**Patch:** `customs/patches/gui.c.patch`
**Touches:** `src/gui.c` — `guiDrawBGSettings()`

## What it changes

Settings screens and dialogs no longer draw the `settings_bg` texture as their background.
They fall through to the animated plasma instead.

## Why

In this fork `settings_bg` is not a settings backdrop at all: the theme uses it as the
artwork layer behind the games list. Drawing it again under every dialog made the menus
look like a different program and buried the plasma the rest of the UI is built around.

## How it works

Upstream:

```c
GSTEXTURE *bg = thmGetTexture(SETTINGS_BG);
if (bg) {
    rmSetBackground(bg);
    return 1;
}
return 0;
```

Here the function simply returns `0`. The caller reads that as "no background was drawn"
and renders the plasma.

The texture itself is untouched: it is still declared in the theme, still loaded, and still
drawn over the games list as a `StaticImage` — see [07 — Theme layout](07-theme-layout.md).
Only this one drawing path stops using it.

## Upstreamable

No. Upstream's behaviour is correct for upstream's themes; this only makes sense together
with the theme layout of this fork.

## How to revert

`git apply -R customs/patches/gui.c.patch`. Note that `src/gui.c` also carries
[06](06-remember-last-played.md) as a separate patch file; the two touch distant regions
and revert independently.
