# 08 — Boot version name

**Patch:** `customs/patches/gui.c.boot-version-name.patch`
**Touches:** `src/gui.c` — `guiDrawBootVersion()`

## What it changes

The line in the bottom-right corner of the boot screen reads `wOPL-new-ui <version>` instead
of `wOPL <version>`.

## Why

The version shown while the loader starts is what someone reads off a photo or a recording
when reporting a problem. `wOPL v1.0` names the upstream project and a version number that
upstream never released — the tag is this fork's. Saying `wOPL-new-ui v1.0` makes the line
answer the actual question: which build is this.

## How it works

`guiDrawBootVersion()` formats the string and right-aligns it 16 pixels from the edge:

```c
snprintf(version, sizeof(version), "wOPL-new-ui %s", WOPL_VERSION);
...
width = rmUnScaleX(fntCalcDimensions(font, version));
x = screenWidth - width - 16;
```

The width is measured from the string itself, so the longer name simply starts further
left; nothing else moves. `WOPL_VERSION` comes from the `Makefile`
(`-DWOPL_VERSION=\"$(wOPL_VERSION)\"`), which uses the git tag when the commit being built
is tagged exactly — so a release build reads `wOPL-new-ui v1.0`, and an untagged local
build reads the `v1.2-beta-<rev>` string instead.

## Not changed

The About screen still reads `Double Unofficial Open PS2 Loader <version>`
(`guiShowAbout()`). That screen is where the upstream project is credited, so it keeps
upstream's name.

## Upstreamable

No — it is the fork's own name.

## How to revert

`git apply -R customs/patches/gui.c.boot-version-name.patch`.
