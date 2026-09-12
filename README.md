# wOPL-new-ui

A personal build of **wOPL** for the PlayStation 2, with a reworked interface and a few
behaviour fixes. This repository is a fork of
[ps2homebrew/wOPL](https://github.com/ps2homebrew/wOPL).

## What wOPL is

wOPL (*Double Unofficial Open PS2 Loader*) is a fork of Open PS2 Loader, the homebrew game
loader for the PlayStation 2. It boots PS2 games stored as disc images on USB drives,
internal HDD, SMB shares and MMCE devices (SD2PSX, MemCard PRO 2), with per-game settings,
cover art, cheats, virtual memory cards and an optional Neutrino core.

If you are looking for the original project, its documentation, releases and issue tracker,
go upstream. This fork exists to keep one specific build reproducible, not to replace it.

## What this fork changes

**Interface**

- Dark default palette (black background, white text, blue selection, olive UI text)
  instead of the light one.
- Settings and dialog screens drop the static background and fall through to the animated
  plasma; the background image stays where it belongs, behind the games list.
- Reworked list and coverflow layouts: repositioned list, covers, disc icon and menu icon,
  reflections turned off, and the game id shown next to the cover in list view.

**Behaviour**

- The wOPL config folder is looked up on the memory card that actually holds it, instead of
  defaulting to whichever slot happens to have a card in it first.
- No cover-art pre-delay on MMCE devices, which are fast enough not to need it.
- Per-game settings can be read from a packed `CFG/cfg.tar`, so thousands of small `.cfg`
  files do not have to live loose on the device.
- The last played game is restored even when it is the first entry of the unsorted list —
  previously that one game was silently never remembered. Submitted upstream as
  [ps2homebrew/wOPL#435](https://github.com/ps2homebrew/wOPL/pull/435).

Every item above is documented in detail under [`docs/`](docs/), one page per change, with
the files it touches and how to revert it.

## Repository layout

| Path | What it is |
|---|---|
| `src/`, `include/`, `misc/`, `modules/`, ... | Upstream wOPL source, with the customizations already applied |
| `customs/` | Custom audio and gfx with their art working files, each customization as a standalone patch against upstream, and the golden theme reference |
| `dist/` | Compiled ELFs, named after the upstream revision plus the build date |
| `docs/` | One page per customization, plus the build pipeline |

`customs/` is reference material — the customizations themselves are already committed in
the source tree. See [`docs/build-pipeline.md`](docs/build-pipeline.md).

## Building

Same toolchain as upstream: ps2dev v2.0.0, built here under WSL (Ubuntu 24.04).

```sh
make clean release
```

The result is `WOPNPS2LD.ELF`. Copy it to your PS2 and launch it like any other homebrew
ELF. There is nothing to patch or overlay first: everything this fork changes is already in
the tree. Details in [`docs/build-pipeline.md`](docs/build-pipeline.md).

## Current baseline

Upstream `ce94bd9`. The fork deliberately stays pinned to a known-good revision and moves
forward only on purpose, so that a regression can always be traced to either an upstream
change or a local one, never to both at once.

## Credits and licence

All credit for wOPL and Open PS2 Loader goes to the upstream authors and contributors —
see `CREDITS`. Licensed under the Academic Free License version 3.0, same as upstream; see
`LICENSE`. The custom audio and artwork in `customs/` are the work of this fork's author.
