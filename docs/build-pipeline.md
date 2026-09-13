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

`./build.sh` is the whole local build: it sets the toolchain environment, cleans, runs
`make release`, and copies the result into `dist/` under the name this repository uses.

```sh
./build.sh              # -> dist/wOPL-new-ui-<short sha>-<YYYY-MM-DD>.ELF
./build.sh --no-clean   # incremental, for iterating on a source change
```

A clean build takes a couple of minutes; the full output is kept in `build.log`
(gitignored). The script refuses to start if the toolchain or a required tool is missing,
warns when the tree is dirty — the short sha in the filename then does not fully describe
the binary — and commits nothing: `dist/` is ignored, so a local build never reaches the
repository.

By hand, it is the same two commands with the environment in place:

```sh
export PS2DEV=/opt/toolchains/ps2dev
export PS2SDK="$PS2DEV/ps2sdk"
export GSKIT="$PS2DEV/gsKit"
export PATH="$PATH:$PS2DEV/bin:$PS2SDK/bin:$PS2DEV/ee/bin:$PS2DEV/iop/bin:$PS2DEV/dvp/bin"

make clean release
```

The toolchain lives at `/opt/toolchains/ps2dev`; export `PS2DEV` to build against an
install somewhere else. Also needed: `make`, `git`, `zip`, and `python3` with PyYAML
(`lang_compiler.py` uses it).

Two things worth knowing, both of which `build.sh` already handles:

- The `release` target's last step builds a `.ZIP`. Without `zip` installed it exits 127
  *after* the ELF is already complete, so gate any automation on the ELF existing rather
  than on `make`'s exit status.
- `make clean` wipes `obj/`, `asm/`, the per-module artefacts and the loose ELFs, but
  leaves `modules/**/*.notiopmod.elf` behind; delete those too for a truly clean tree.

Building from a native Linux path is considerably faster than from a Windows drive mounted
under `/mnt`, where every file stat crosses the filesystem bridge.

The build needs no network beyond `download_lwNBD.sh`, which clones the lwNBD library the
network module links against — see [Languages](#languages) for what used to be fetched here
and no longer is.

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
taking an upstream change is now a real git operation rather than a patch re-apply — see
[Upstream](#upstream) for how that is done here.

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

## Upstream files this fork removed

The upstream tree carries tooling for things this fork does not do, and every one of them
was dead weight in the repository root:

| Removed | What it was |
|---|---|
| `download_cfla.sh`, `.clang-format`, `.clang-format-ignore` | the clang-format lint, driven by the `format` / `format-check` targets and upstream's `check-format.yml`. The workflow was already not replicated here; the targets and the script that fetched the linter are gone with it |
| `lng_pack.sh` | packages the ~30-language pack for an upstream release. This fork ships English only and nothing invoked it |
| `download_lng.sh`, `lng/README.md` | the translations clone every build depended on, and the translator guide describing it. See [Languages](#languages) |
| `lang_decompiler.py` | the translator-facing inverse of `lang_compiler.py` (`.lng` back to YAML). Nothing invoked it; `lang_compiler.py` stays, because the English text compiled into the ELF comes from it |
| `CMakeLists.txt` | a CMake wrapper that only shells out to the `Makefile`, for IDEs that expect one |
| `CHANGELOG`, `OLD_DETAILED_CHANGELOG` | frozen history from the OpenUsbLd and Mercurial eras, 110 KB of it. The changelog a build produces is `DETAILED_CHANGELOG`, generated by `make_changelog.sh` |

`.editorconfig` and `.gitattributes` were left alone: unlike the above they are in effect
every day, setting editor indentation and the LF normalization this tree is checked out
with on Windows.

## CI

`.github/workflows/ci.yml` — *Build & Release*:

- **Every push and PR** builds in the pinned `ghcr.io/ps2homebrew/ps2homebrew` toolchain
  image and keeps the result as a workflow artifact: `wOPL-new-ui-<id>.ELF`, a plain
  `WOPNPS2LD.ELF` for setups configured to boot that name, and the packaged `.ZIP`.
  `<id>` is the tag on a tagged build, the short commit otherwise.
- **Pushing a `v*` tag** additionally publishes a GitHub Release carrying exactly one
  file, `OPL.ELF` — the same loader, under the name the PS2 setups this fork is built for
  boot. The longer names stay on the workflow artifact, where traceability is what matters;
  a release page listing three names for one binary only asks the reader which to pick.
  Re-tagging a version drops whatever an earlier run of that tag had attached, because the
  upload step adds and replaces but never removes.

Nothing else creates a release. Upstream's CI cut a fresh prerelease and tag on every
single push; that is deliberately not replicated.

The release body is `.ci/release-notes.md`, written by hand before tagging, plus a
provenance line the workflow appends. Rewrite that file as part of preparing a release —
whatever it says when the tag is pushed is what gets published.

## Languages

This fork ships **English only** and publishes no language pack.

The loader's own English text is not downloaded from anywhere: `lng_tmpl/_base.yml` lives
in this repository and `lang_compiler.py` turns it into `src/lang_internal.c` and
`include/lang_autogen.h`, which are compiled into the ELF. Those two files are generated,
not tracked, and building them is all the `languages` target does. A developer adding a new
UI string adds it to `lng_tmpl/_base.yml`.

Nothing else about languages happens at build time any more. Upstream's `all` and `release`
targets also depended on `download_lng`, which shallow-cloned the translations repository
([`Double-Unofficial-Open-PS2-Loader-lang`](https://github.com/ps2homebrew/Double-Unofficial-Open-PS2-Loader-lang))
into `lng_src/`, and on a `languages` target that compiled all 31 translations into
`lng/lang_*.lng` — a clone and ~30 files produced on every single build, for a pack this
fork does not publish, then thrown away. The clone, the translation list, the rules that
built the `.lng` files and `download_lng.sh` are gone; `make realclean` still clears a
stale `lng_src/` from a checkout that predates this.

None of that changes what the loader can do on the console: `lngLoadFromFile()`
(`src/lang.c`) still picks up any `.lng` a user drops on the device, exactly as before.
Translators still work in the upstream language repository, which is where those files come
from.

## Builds from the desktop

`dist/` holds the ELFs built locally, named `wOPL-new-ui-<short sha>-<YYYY-MM-DD>.ELF`,
which is what `./build.sh` writes. The whole directory is **gitignored**: it is a local
workspace, not part of the repository. What a release ships is built by CI from the tag, so
a binary here would only be a second, unverifiable copy of it — and at ~1.5 MB each, one
that stays in the history forever.

The two ELFs that were tracked before this rule are still reachable in the history, under
`dist/` at `2f790da^`.

A build worth remembering gets an entry in [`CHANGELOG.md`](../CHANGELOG.md) — a
milestone, a behaviour change, something handed to someone to test. That file replaced the
Portuguese build log this fork kept while the customizations lived outside the repository;
the log's entries are condensed into it, and the original is in the history at
`git show 851e1c8^:docs/BUILD-LOG.pt-BR.md`.

The binaries stay local: if someone else needs a build, the release page is where it comes
from.

## Upstream

`origin` points at `ps2homebrew/wOPL` so the upstream history stays visible from here.
Nothing pulls from it automatically: the fork stays pinned to a known-good revision and
moves forward only when someone decides it should.

When it does, the way in is **`git cherry-pick`**, one upstream commit at a time — not a
merge of their branch. That keeps this tree what it is: upstream code plus the
customizations, minus the files above, with nothing arriving that nobody chose. It is also
why deleting an upstream file here costs nothing — a merge would have raised a
delete/modify conflict on each one, a cherry-pick only conflicts if the commit being picked
touches a file that is gone, which is the moment to decide whether you want that change at
all.
