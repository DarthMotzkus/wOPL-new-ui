# Build pipeline

How the ELFs in `dist/` are produced.

## The short version

The repository is the source of truth. Every customization is committed on `main`, so
building is a plain compile of what is checked out:

```sh
make clean release
```

Toolchain: ps2dev v2.0.0, built here under WSL (Ubuntu 24.04). The output is
`WOPNPS2LD.ELF` in the repository root; rename it to whatever you like and copy it to the
PS2. Nothing is patched, overlaid, downloaded or re-applied at build time.

The language files come from a separate repository and are fetched once by
`download_lng.sh` into `lng_src/`, which the `Makefile` consumes and `.gitignore` excludes.

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
  `WOPNPS2LD.ELF` for setups configured to boot that name, the packaged `.ZIP` and the
  language pack. `<id>` is the tag on a tagged build, the short commit otherwise.
- **Pushing a `v*` tag** additionally publishes a GitHub Release with those files.

Nothing else creates a release. Upstream's CI cut a fresh prerelease and tag on every
single push; that is deliberately not replicated.

The release body is `.ci/release-notes.md`, written by hand before tagging, plus a
provenance line the workflow appends. Rewrite that file as part of preparing a release —
whatever it says when the tag is pushed is what gets published.

The language pack step is `continue-on-error`: it comes from a separate upstream
repository, and a bad day on their side should not fail a build of this one. When it does
not build, the step goes yellow and the pack is simply absent from the release.

The workflows upstream keeps but this fork does not: the 16-way build matrix
(`EXTRACT_FEATURES`/`GSM`/`CHEAT`/`PADEMU` combinations) and the debug matrix, which exist
to catch build breaks in configurations nobody here ships; `check-format.yml`, a
clang-format lint; `OPLTestISO.yml`, which builds the test ISO under `labs/`; and the
downloads-badge job, which is about their release counters.

## Publishing a build from the desktop

`dist/` holds published ELFs, named `wOPL-new-ui-<short sha>-<YYYY-MM-DD>.ELF`. The
upstream `.gitignore` ignores `*.ELF` globally, so `dist/*.ELF` is explicitly un-ignored —
keep that negation in place or published builds will silently stop being tracked.

## Upstream

`origin` points at `ps2homebrew/wOPL` so the upstream history stays visible from here.
Nothing pulls from it automatically: the fork stays pinned to a known-good revision and
moves forward only when someone decides to merge.
