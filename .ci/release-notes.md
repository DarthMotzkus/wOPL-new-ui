<!--
This file is the body of the next GitHub Release, verbatim.

Rewrite the "What's new" section before pushing a v* tag. Whatever is here when the
tag is pushed is what gets published, so a stale file ships stale notes.

The "**Build:**" provenance line at the bottom is NOT written here: .github/workflows/ci.yml
generates it at release time and appends it after a horizontal rule. Do not add it by hand.

Write for someone who is going to copy an ELF onto a memory card, not for someone reading
the commit log: say what changed on screen or in behaviour, and who needs to care. The
release notes are not generated from commits on purpose -- generated notes bury the one
thing that matters under every routine commit.
-->

## What's new in v1.0

First release of **wOPL-new-ui** as its own build: upstream wOPL `ce94bd9` with a reworked
interface and four behaviour changes already applied. There is nothing to patch, theme or
overlay after copying it.

**Interface**

* **Dark by default.** Black background, white text, blue selection and olive UI text
  instead of upstream's light palette, with custom navigation, confirm, cancel, message,
  transition and boot sounds, and custom disc, case and settings artwork.
* **Settings and dialogs run on the animated plasma** rather than a static image: the
  background picture stays where it belongs, behind the games list.
* **Reworked list and coverflow layouts.** Repositioned list, covers, disc icon and menu
  icon, reflections off, and the game id shown next to the cover in list view.

**Behaviour**

* **Settings save on the memory card that actually holds them.** With a card in each slot,
  wOPL aimed at whichever slot had a card first and failed to write when the `wOPL_1_2/`
  folder lived on the other one. It now picks the slot with the folder.
* **The last played game is remembered even when it is the first entry of the unsorted
  list.** That one game — in practice the most recently copied one — was silently never
  restored, and the auto-start countdown never ran for it. Submitted upstream as
  [ps2homebrew/wOPL#435](https://github.com/ps2homebrew/wOPL/pull/435).
* **Per-game settings can be read from a packed `CFG/cfg.tar`**, so thousands of small
  `.cfg` files do not have to live loose on the device. A loose `CFG/<id>.cfg` still wins
  when it exists. Entries in the tar have to be in the new (libconfig) format and stored
  under the bare name `<id>.cfg`, with no `CFG/` prefix — which is what
  `cd CFG && tar -cf cfg.tar *.cfg` produces, and what OPL Manager's packer does not.
* **No cover-art pre-delay on MMCE devices** (SD2PSX, MemCard PRO 2): covers and per-game
  info load as the cursor moves, instead of after an idle pause the hardware does not need.
  Other devices keep the upstream delay.

**What to download**

`WOPNPS2LD.ELF` is the loader — copy it to your PS2 and launch it like any other homebrew
ELF. `wOPL-new-ui-v1.0.ELF` is the same binary under a name that says which build it is,
and the `.ZIP` is both of those plus the changelog, credits and licence. This fork ships
**English only** and publishes no language pack.

**Full changelog:** [every commit up to v1.0](https://github.com/DarthMotzkus/wOPL-new-ui/commits/v1.0) — baseline: upstream [`ce94bd9`](https://github.com/ps2homebrew/wOPL/commit/ce94bd9a2af8d5224d311a088625da112c1cb8aa).
