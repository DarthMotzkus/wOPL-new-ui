# 01 — Default colours

**Patch:** `customs/patches/common.c.patch`
**Touches:** `src/common.c` — `setDefaultColors()`

## What it changes

The fallback palette wOPL uses when a theme does not define its own colours goes from the
upstream light scheme to a dark one.

| Role | Upstream | Here |
|---|---|---|
| Background | `#FFFFFF` white | `#000000` black |
| Text | `#5C5C5C` grey | `#FFFFFF` white |
| Selected text | `#2A2A2A` near-black | `#0079F5` blue |
| UI text | `#FFFFFF` white | `#B0B300` olive |
| Plasma blend | `#FFFFFF` white | `#000000` black |

## Why

The rest of this fork's interface is built around a dark background. The plasma blend
colour matters most: with the upstream white the animated background washes out, and the
custom artwork sitting on top of it loses contrast.

## How it works

`setDefaultColors()` fills the five global colour arrays at startup. Themes that declare
their own colours override them; themes that do not now inherit the dark palette. The
theme files in `misc/` intentionally leave `plasma_blend_color` undefined so that the value
set here is the one that applies — see [07 — Theme layout](07-theme-layout.md).

## Upstreamable

No. This is a personal taste choice, not a defect.

## How to revert

`git apply -R customs/patches/common.c.patch`, or drop that file from the patch set before
building.
