# wOPL-new-ui documentation

One page per customization this fork carries on top of upstream wOPL. Each page is
self-contained and states the same things in the same order, so it can be read on its own
(by a person or by an AI assistant) without the rest of the repository for context:

- which patch file carries it and which source files it touches
- what it changes, in behaviour terms
- why it exists
- how it works, at the level of the actual code
- whether it is upstreamable
- how to revert it

## Changes

| Page | Area | Summary |
|---|---|---|
| [01 — Default colours](changes/01-default-colors.md) | UI | Dark palette instead of the light default |
| [02 — Config card slot](changes/02-config-card-slot.md) | Config | Use the memory card that actually holds the wOPL folder |
| [03 — MMCE cover delay](changes/03-mmce-cover-delay.md) | UI | No cover-art pre-delay on MMCE devices |
| [04 — Per-game config from cfg.tar](changes/04-per-game-config-from-tar.md) | Config | Read per-game settings from a packed tar |
| [05 — Settings background](changes/05-settings-background.md) | UI | Plasma behind settings/dialog screens |
| [06 — Remember last played](changes/06-remember-last-played.md) | Fix | Restore the last played game when it is the first list entry |
| [07 — Theme layout](changes/07-theme-layout.md) | UI | Asset positions for the list and coverflow views |

## Process

- [Build pipeline](build-pipeline.md) — how the ELF is produced, how the customizations are
  re-applied on top of upstream, and why `customs/` in this repository is a snapshot rather
  than a build input.

## Conventions

- Every change lives as a standalone patch in `customs/patches/`, generated with
  `git diff HEAD -- <path>` against upstream. One logical change per file.
- The source tree in this repository already has all of them applied. The patches are kept
  so a single change can be reverted, rebased or submitted upstream on its own.
- A patch named `<file>.<topic>.patch` is a second, independent change to a file that
  already has one; the suffix keeps the apply order stable and predictable.
