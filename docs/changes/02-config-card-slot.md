# 02 — Config card slot

**Patch:** `customs/patches/config_wopl.c.patch`
**Touches:** `src/config_wopl.c` — new `wopl_mc_slot()`, used by `pick_default_config_dir()`,
`probe_config_path()` and `try_save_all_mc()`

## What it changes

wOPL looks for its config folder on the memory card that actually holds it, instead of on
whichever slot happens to contain a card first.

## Why

Upstream calls `sysCheckMC()`, which returns the first slot with any card present and
prefers `mc0`. If the wOPL folder lives on `mc1` and a plain save card sits in `mc0`, the
settings are read from — and written to — the wrong card. The symptom is settings that
silently reset between boots, or two divergent config folders.

## How it works

`wopl_mc_slot()` mirrors the logic of `checkMC()` / `sbGetmcID()` but answers a different
question, in this order:

1. `mc0:<WOPL_CONFIG_NAME>/` exists → slot 0
2. `mc1:<WOPL_CONFIG_NAME>/` exists → slot 1
3. `mc0:/` mounts → slot 0
4. `mc1:/` mounts → slot 1
5. otherwise → `-1`

In other words: prefer the card that already holds the config, and only then fall back to
the first card present. The return contract matches what the call sites already expect
(`mc >= 0`, `mc & 1`), so the three replacements are drop-in.

The probe is read-only — `opendir()` / `closedir()`, no writes, no side effects and no
dependency on initialization order, which is why it is safe to call from the config path
resolution that runs early at boot.

## Upstreamable

Probably yes, as a bug fix — the behaviour it corrects is wrong for anyone with two cards.
It has not been submitted.

## How to revert

The patch also carries [03](03-mmce-cover-delay.md) and part of
[04](04-per-game-config-from-tar.md), so reverting the whole file is coarse. To drop only
this change, restore the three `sysCheckMC()` call sites and delete `wopl_mc_slot()`.
