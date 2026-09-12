# 04 — Per-game config from `CFG/cfg.tar`

**Patches:** `customs/patches/config_wopl.c.patch`, `customs/patches/config_wopl.h.patch`,
`customs/patches/supportbase.c.patch`
**Touches:** `src/config_wopl.c` — new `wOPLPerGameLoadBuf()`; `include/config_wopl.h` — its
declaration; `src/supportbase.c` — `sbPopulateConfig()`

## What it changes

Per-game settings can be read from a single packed `CFG/cfg.tar`, the same way cover art
and cheats are already read from `ART/art.tar` and `CHT/cht.tar`. A loose
`CFG/<game id>.cfg` still wins when it exists.

## Why

A large library means thousands of tiny `.cfg` files. On a memory card or an MMCE device
that is slow to enumerate and wasteful in allocation units. One tar keeps the per-game
settings without the file-count penalty.

## How it works

`wOPLPerGameLoadBuf(buf, size, cfg)` is `wOPLPerGameLoad()` reading from memory instead of
from a path: it copies the buffer, NUL-terminates it, parses it with libconfig's
`config_read_string()` and runs the same `parse_per_game()`. New (libconfig) format only —
there is no legacy fallback for tar entries.

In `sbPopulateConfig()` the lookup order becomes:

1. `wOPLPerGameLoad(cfg_path, pgcfg)` — the loose `CFG/<id>.cfg`
2. if that fails, `tarFind(TAR_KIND_CFG, "<id>.cfg")` and `tarGet(...)`, then
   `wOPLPerGameLoadBuf()` on the returned buffer, which is freed right after

Everything downstream (format/media/size auto-detection) is untouched.

### Requirements for the tar

These are easy to get wrong and produce a silent "no settings found":

- Entry names must be **bare**: `SLUS_202.28.cfg`, not `CFG/SLUS_202.28.cfg`. The lookup
  key is the file name alone.
- The archive must be plain **ustar**, not PAX. A PAX archive carries extended headers the
  loader does not parse.
- Only `.cfg` entries are served from the tar. `.info` files are never read from it and
  must stay loose.

## Upstreamable

Plausibly yes — it mirrors an existing upstream pattern (art and cheat tars) rather than
inventing one. It has not been submitted.

## How to revert

Revert `supportbase.c.patch` to restore the plain `wOPLPerGameLoad(cfg_path, pgcfg)` call.
`wOPLPerGameLoadBuf()` can then stay in place unused, or be dropped along with its
declaration.
