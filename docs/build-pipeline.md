# Build pipeline

How the ELFs in `dist/` are produced, and how the customizations survive an upstream
update.

## Plain build

Standard wOPL build, ps2dev v2.0.0 toolchain, run here under WSL (Ubuntu 24.04):

```sh
make clean release
```

Output is `WOPNPS2LD.ELF` in the repository root. The source tree in this repository
already has every customization applied, so this is all that is needed to reproduce a
binary equivalent to the one in `dist/`.

## Automated pipeline

The builds in `dist/` come from a scripted pipeline that keeps the customizations separate
from the upstream source. The customizations are **not** stored as commits on top of
upstream; they are re-applied from scratch on every build.

The inputs live in a directory outside the repository:

```
<build inputs>/
  audio/*.adp       overlaid wholesale onto audio/
  gfx/*.png         overlaid wholesale onto gfx/
  patches/*.patch   applied with `git apply --3way`
  util/             working files the artwork was drawn from (not consumed by the build)
```

Steps:

1. **Revert.** Every path named in a patch header, and every overlay target, is reset to
   `HEAD`, so the patches always apply to a clean upstream state.
2. **Sync — opt-in only.** The pipeline never pulls from origin on its own. It builds the
   checkout exactly as it stands unless a sync is explicitly requested. The fork stays
   pinned to a known-good upstream revision, and moves forward on purpose.
3. **Structure check.** Each custom `.adp` must still exist in `audio/` and still be
   referenced by the `Makefile`; each custom `.png` must still be listed in `PNG_ASSETS`;
   each patch must still apply. Any mismatch aborts the build *before* anything is
   overlaid, leaving the tree at plain upstream so the breaking change can be inspected.
4. **Apply.** Binaries are copied over, patches applied with `git apply --3way` — so
   upstream improvements in untouched regions of a patched file survive.
5. **Build, place, clean.** The ELF is archived under a name carrying the upstream short
   SHA; the previous build is kept.

### Why patches and not commits

Binary assets have no useful merge semantics, so they are overlaid wholesale. Source and
theme changes are kept as one patch per logical change, which means each one can be
reverted, rebased or submitted upstream on its own — [06](changes/06-remember-last-played.md)
went upstream exactly that way.

### Checking a patch still applies

`git apply --check --3way` reports success in cases where the real apply would not behave
as expected, because the three-way fallback can resolve against blobs rather than the
working tree. Verify with an actual apply on a clean tree, not with the dry run alone.

### Apply order

Patches are applied in glob (alphabetical) order. When two patches touch the same file, the
file names decide who goes first — `gui.c.patch` before `gui.c.remember-last.patch`. That
ordering is deliberate: the second patch was generated against the current upstream tip and
edits a region far above the first one, so it applies with no offset once the first is in.

## `customs/` in this repository is a snapshot

The pipeline reads its inputs from the external directory above, by absolute path. The copy
committed under `customs/` is **never read by the build**. It exists so the inputs are
backed up and reviewable alongside the code they produce.

That means it can drift: edit a patch in the working directory, forget to refresh the copy,
and the repository shows something the binary was not built from. When the inputs change,
re-copy them in the same commit as the resulting source change.
