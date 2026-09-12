# Build pipeline

How the ELFs in `dist/` are produced.

## The short version

The repository is the source of truth. Every customization is committed on `main`, so
building is a plain compile of what is checked out:

```sh
make clean release
```

Toolchain: ps2dev v2.0.0. The output is `WOPNPS2LD-<version>.ELF` plus a packaged `.ZIP` in
the repository root; rename the ELF to whatever your PS2 setup boots. Nothing is patched,
overlaid or re-applied at build time.

## Building locally

The toolchain lives at `/opt/toolchains/ps2dev` and has to be on the environment before
`make` will find its compilers:

```sh
export PS2DEV=/opt/toolchains/ps2dev
export PS2SDK="$PS2DEV/ps2sdk"
export GSKIT="$PS2DEV/gsKit"
export PATH="$PATH:$PS2DEV/bin:$PS2SDK/bin:$PS2DEV/ee/bin:$PS2DEV/iop/bin:$PS2DEV/dvp/bin"

make clean release
```

Also needed: `make`, `git`, `zip`, and `python3` with PyYAML (`lang_compiler.py` uses it).

Two things worth knowing:

- The `release` target's last step builds a `.ZIP`. Without `zip` installed it exits 127
  *after* the ELF is already complete, so gate any automation on the ELF existing rather
  than on `make`'s exit status.
- `make clean` wipes `obj/`, `asm/`, the per-module artefacts and the loose ELFs, but
  leaves `modules/**/*.notiopmod.elf` behind; delete those too for a truly clean tree.

Building from a native Linux path is considerably faster than from a Windows drive mounted
under `/mnt`, where every file stat crosses the filesystem bridge.

The language files come from a separate repository and are fetched by `download_lng.sh`
into `lng_src/`, which the `Makefile` consumes and `.gitignore` excludes — see
[Languages](#languages) below for what actually depends on it.

## History: the patch pipeline (retired)

Earlier builds of this fork worked the other way around. The tree was kept at plain
upstream and the customizations lived **outside** the repository, as a folder of inputs:
custom `.adp` and `.png` assets overlaid wholesale, and one `.patch` file per logical source
or theme change. Every build reverted the touched paths to `HEAD`, verified that upstream
still referenced each asset the same way, re-applied everything with `git apply --3way`,
and only then compiled.

That design existed to survive upstream updates: a patch that still applied meant an
upstream change had not broken the customization, and one that failed pointed straight at
the conflict.

It was retired once this fork got its own repository. Keeping the customizations as commits
is simpler, reviewable, and makes the tree reproducible on its own. The trade-off is that
rebasing onto a newer upstream is now a real merge rather than a patch re-apply — which is
the normal cost of maintaining a fork, and is a deliberate, manual step.

Two artefacts of that era are still worth having, and live in `customs/`:

- `customs/patches/` — each customization as a standalone diff against upstream. Kept so a
  single change can be reverted in isolation, or submitted upstream on its own:
  [06 — Remember last played](changes/06-remember-last-played.md) went upstream exactly that
  way. They are **not** applied by any build; the code they describe is already committed.
- `customs/audio/`, `customs/gfx/`, `customs/util/` — the custom assets as standalone files
  plus the working files they were drawn from. The assets themselves are already in `audio/`
  and `gfx/`; these copies are the originals, kept together with their sources.
- `customs/reference/` — golden `theme_list.cfg` / `theme_coverflow.cfg` and
  `THEME_POSITIONS.md`, the authoritative record of the theme asset positions. If the
  on-screen layout ever drifts, restore from these rather than re-deriving it. See
  [07 — Theme layout](changes/07-theme-layout.md).

If you find a reference anywhere to an external customs folder, a structure check, or
patches being applied at build time, it is a leftover from this retired pipeline.

## CI

`.github/workflows/ci.yml` — *Build & Release*:

- **Every push and PR** builds in the pinned `ghcr.io/ps2homebrew/ps2homebrew` toolchain
  image and keeps the result as a workflow artifact: `wOPL-new-ui-<id>.ELF`, a plain
  `WOPNPS2LD.ELF` for setups configured to boot that name, and the packaged `.ZIP`.
  `<id>` is the tag on a tagged build, the short commit otherwise.
- **Pushing a `v*` tag** additionally publishes a GitHub Release with those files.

Nothing else creates a release. Upstream's CI cut a fresh prerelease and tag on every
single push; that is deliberately not replicated.

The release body is `.ci/release-notes.md`, written by hand before tagging, plus a
provenance line the workflow appends. Rewrite that file as part of preparing a release —
whatever it says when the tag is pushed is what gets published.

## Languages

This fork ships **English only** and publishes no language pack.

The loader's own English text is not downloaded from anywhere: `lng_tmpl/_base.yml` lives
in this repository, and `lang_compiler.py` turns it into `src/lang_internal.c` and
`include/lang_autogen.h`, which are compiled into the ELF. Those two files are generated,
not tracked.

What the upstream translations repository
([`Double-Unofficial-Open-PS2-Loader-lang`](https://github.com/ps2homebrew/Double-Unofficial-Open-PS2-Loader-lang))
provides is the *translated* `.yml` files that become the loose `lng/lang_*.lng` files a
user drops next to the ELF. `download_lng.sh` shallow-clones it into `lng_src/`, which is
gitignored.

That clone still happens during a build, because the stock `Makefile` lists `download_lng`
as a prerequisite of both `all` and `release`. It costs a clone and produces ~30 `.lng`
files that this fork does not publish. Cutting it would mean patching the `release` and
`languages` targets — a divergence in a file upstream edits often — so for now the clone is
tolerated and its output simply ignored.

The workflows upstream keeps but this fork does not: the 16-way build matrix
(`EXTRACT_FEATURES`/`GSM`/`CHEAT`/`PADEMU` combinations) and the debug matrix, which exist
to catch build breaks in configurations nobody here ships; `check-format.yml`, a
clang-format lint; `OPLTestISO.yml`, which builds the test ISO under `labs/`; and the
downloads-badge job, which is about their release counters.

## Builds from the desktop

`dist/` holds the ELFs built locally, named `wOPL-new-ui-<short sha>-<YYYY-MM-DD>.ELF`. The
upstream `.gitignore` ignores `*.ELF` globally, so `dist/*.ELF` is explicitly un-ignored —
keep that negation in place or builds will silently stop being tracked.

`dist/BUILD-LOG.pt-BR.md` is the running log of those builds: what changed in each one and
what still needs testing on real hardware. It lived outside the repository until the tree
became the fork, which made it the one artefact with no backup anywhere; it is versioned
here now. It is written in Portuguese — see the note at the top of the file.

Each tracked ELF is ~1.5 MB and stays in the history forever, so commit a build when it is
worth keeping — a milestone, or one being handed to someone — rather than on every compile.

## Upstream

`origin` points at `ps2homebrew/wOPL` so the upstream history stays visible from here.
Nothing pulls from it automatically: the fork stays pinned to a known-good revision and
moves forward only when someone decides to merge.
