# 03 — MMCE cover delay

**Patch:** `customs/patches/config_wopl.c.patch`
**Touches:** `src/config_wopl.c` — `gMMCEFramesDelay` default

## What it changes

```c
int gMMCEFramesDelay = 0;   // upstream: MENU_MIN_INACTIVE_FRAMES
```

Cover art and per-game info load immediately while scrolling an MMCE list, with no idle
delay first.

## Why

The delay exists so that holding a direction on a slow device does not fire one artwork
load per frame. MMCE hardware (SD2PSX, MemCard PRO 2) is fast enough that the pause is pure
latency: covers visibly lag behind the cursor for no benefit.

The other devices keep `MENU_MIN_INACTIVE_FRAMES` — this changes the MMCE default only.

## How it works

`gMMCEFramesDelay` seeds `itemList->delay` for the MMCE support module. The menu system
only dispatches an artwork/info update once the list has been idle for that many frames, so
zero means "update as soon as the selection changes".

It is only the *default*: the value is still overridable from the settings screen and is
persisted in the config, and `sanitize_frame_delays()` leaves zero alone (it only rejects
negatives).

## Upstreamable

Marginal. It is a defensible default for MMCE, but it is a judgement call about hardware
speed rather than a fix.

## How to revert

Set the initializer back to `MENU_MIN_INACTIVE_FRAMES`, or just raise the delay in the
settings screen — no rebuild needed for the second option.
