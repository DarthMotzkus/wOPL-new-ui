# Changelog

This fork's own history: what was customized, when it landed, and what it was for.
Upstream wOPL's changes are not repeated here — a build generates `DETAILED_CHANGELOG`
from the upstream commit log, and [ps2homebrew/wOPL](https://github.com/ps2homebrew/wOPL)
is where they are described. Upstream appears below only where it broke or reshaped
something this fork maintains.

Entries before v1.0 come from the running build log kept while the customizations still
lived outside the repository, as a folder of patches re-applied on every build. That log
was written in Portuguese, one entry per local build; it is condensed here in English, and
the original stays readable in the history:
`git show 851e1c8^:docs/BUILD-LOG.pt-BR.md`.

Where the log recorded that something still had to be checked on a real PS2, the entry says
so — that status is as of its date, and was not tracked afterwards.

## v1.0 — 2026-09-12

First release of the fork as its own repository, and its first build published from CI.
Baseline: upstream `ce94bd9`. Release notes: [v1.0](https://github.com/DarthMotzkus/wOPL-new-ui/releases/tag/v1.0).

### Interface

- Dark default palette — black background, white text, blue selection, olive UI text —
  replacing upstream's light one, with custom navigation, confirm, cancel, message,
  transition and boot sounds and custom disc, case and settings artwork.
  [01](docs/changes/01-default-colors.md)
- Settings and dialog screens drop the static background and fall through to the animated
  plasma; the background image stays behind the games list, where it belongs.
  [05](docs/changes/05-settings-background.md)
- Reworked list and coverflow layouts: repositioned list, covers, disc icon and menu icon,
  reflections off, and the game id shown next to the cover in list view.
  [07](docs/changes/07-theme-layout.md)

### Behaviour

- The wOPL config folder is looked up on the memory card that actually holds it, instead of
  whichever slot happens to have a card in it first.
  [02](docs/changes/02-config-card-slot.md)
- The last played game is restored even when it is the first entry of the unsorted list —
  in practice the most recently copied game, which was silently never remembered, and never
  got the auto-start countdown. Submitted upstream as
  [ps2homebrew/wOPL#435](https://github.com/ps2homebrew/wOPL/pull/435).
  [06](docs/changes/06-remember-last-played.md)
- Per-game settings can be read from a packed `CFG/cfg.tar`, so thousands of small `.cfg`
  files need not live loose on the device. [04](docs/changes/04-per-game-config-from-tar.md)
- No cover-art pre-delay on MMCE devices (SD2PSX, MemCard PRO 2), which are fast enough not
  to need it. [03](docs/changes/03-mmce-cover-delay.md)

### Repository and build

- The customizations became commits on `main`; the patch pipeline that re-applied them at
  build time was retired. `customs/` keeps each one as a standalone diff, plus the assets
  and the golden theme reference.
- `build.sh` builds locally in one command, into `dist/`, which is local only.
- CI builds every push in the pinned ps2homebrew toolchain image; a `v*` tag publishes a
  release carrying one file, `OPL.ELF`.
- The upstream tooling this fork does not use was removed — the clang-format lint, the
  language-pack packer, the CMake wrapper, the frozen changelogs — and the language pack
  itself was cut from the build: `languages` now produces only the English text compiled
  into the ELF, from the in-tree `lng_tmpl/_base.yml`, instead of cloning the translations
  repository and generating 31 `.lng` files on every build.

## Build history before v1.0

### 2026-09-12 — remember the last played game when it is first in the list

Building the list marks the remembered game and raises an internal flag; the alphabetical
sort that follows only honours the selection when that flag is up. The **first** raw list
entry took an `else if` branch that selected it for being first and never raised the flag,
so the sort sent the cursor back to the top — and since the directory scan stacks files in
reverse, that first entry is the most recently copied ISO. Fixed in `src/gui.c`
(`GUI_OP_APPEND_MENU`) by making the branch independent. Does not cover the Favourites tab,
which never remembers, or the automatic tab switch when the game is on another device.
Hardware check pending at the time.

Same entry: `git pull` stopped being part of the build. The build compiles the checkout as
it is, and syncs with upstream only when told to.

### 2026-06-27 — theme asset positions restored from the older ELF

The list layout had drifted. The known-good `OPL_old.ELF` was unpacked (ps2-packer/LZMA,
calibrated with the toolchain's own packer) and its embedded theme cfgs extracted; the
drift was confined to `misc/theme_list.cfg`. Restored: list at `x=20 y=57 h=342`, cover at
`-61/-271` (apps `-61/-199`), disc icon at `-245/-195 wsX=-210`, `lm_case_shadow` dropped.
The golden reference was saved so the layout can be restored rather than re-derived —
today `customs/reference/`. Hardware check pending at the time.

### 2026-06-27 — per-game settings read from `CFG/cfg.tar` again

Upstream's libconfig migration orphaned the packed path: `TAR_KIND_CFG` was defined in
`tar.c` but nothing consumed it, so the per-game loader only read a loose `CFG/<id>.cfg`.
ART and CHT still came from their tars; CFG alone had been left out. Restored with
`wOPLPerGameLoadBuf()` in `config_wopl.c` and a fallback in `sbPopulateConfig()`, loading
the tar on demand exactly as ART and CHT do. Entries must be in the new libconfig format.

### 2026-06-27 — settings save on the memory card that holds them

Upstream's new config system used `sysCheckMC()`, which picks the first slot with a card in
it, preferring `mc0`. With an ordinary card in mc0 and the MMCE config card in mc1 it aimed
at mc0, where `wOPL_1_2/` does not exist, and failed to create the folder — the "error
writing settings" everyone with two cards hit. The old code used `sbGetmcID()`, which
prefers the slot that has the folder. Fixed with a local `wopl_mc_slot()` helper replacing
the three `sysCheckMC()` uses.

### 2026-06-26 — upstream's libconfig rewrite absorbed

24 upstream commits, 80 files: `config.c` became `config_migration.c` + `config_wopl.c` and
the config files moved to libconfig syntax, which forced both theme patches to be rewritten
from scratch on the new base. Upstream also removed the game id from the default theme —
restored here — and made zero frame delay legal, which is what the MMCE cover-delay change
above builds on. Neutrino and VMC support widened; several `Device_*` / `Scan_*` icons were
dropped and `Vmode_ntsc/pal` renamed to `Region_*`, none of which touched this fork's own
assets.

### 2026-06-09 — upstream coverflow work; theme patches rebased by hand

17 upstream commits: coverflow crash fix, its own navigation sound, a
`coverflow_cover_offset` theme parameter, PadEmu/GSM/Cheat status icons with new `info18/19/20`
theme sections, game size computed at boot, and the MMCE game id fix. Both theme cfgs
conflicted and were resolved by hand, keeping this fork's colours, layering and
reflection settings alongside upstream's additions; the patches were regenerated on the new
base so later builds applied cleanly.

### 2026-05-26 — grayscale PNG support (contributed upstream)

`src/textures.c` learned to read grayscale and grayscale+alpha PNGs instead of failing on
them. This one went the other way: it is this fork author's patch, merged upstream by
Wolf3s crediting @DarthMotzkus and closing issue #225.

### 2026-05-25 — upstream: the animated logo returns

8 upstream commits: the animated main-menu logo came back as 21 frames, coverflow
improvements (#230), and a fix for core-loader state leaking between games launched in one
session (#228). Upstream also touched `src/gui.c`, which this fork patches; the patch
applied cleanly.

### 2026-05-24 — upstream: on-demand TAR loading

4 upstream commits, the largest reworking how `ART/art.tar`, per-game CFG and CHT tars are
read: on demand rather than parsing the whole tarball up front (`art_tar.c` became
`tar.c`), with the BDM, ETH, HDD and MMCE backends adapted to it. Less memory on large
libraries; transparent in use. No local patch was affected.
