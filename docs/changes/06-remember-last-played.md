# 06 — Remember last played

**Patch:** `customs/patches/gui.c.remember-last.patch`
**Touches:** `src/gui.c` — `guiHandleOp()`, case `GUI_OP_APPEND_MENU`
**Upstream PR:** [ps2homebrew/wOPL#435](https://github.com/ps2homebrew/wOPL/pull/435)

## What it changes

With "remember last played" enabled, exactly one game per device list was never restored,
and the Last Played Auto Start countdown never fired for it. This makes it work for every
entry.

## Why

The failing game looks arbitrary from the outside: the id is written correctly to
`wopl_last_played.cfg`, but on the next boot the list opens on its first item. It is
whichever game ends up at index 0 of the *unsorted* list, which in practice is usually the
most recently copied ISO — so the bug appears to move from title to title as the library
grows.

## How it works

`updateMenuFromGameList()` (`src/menusys.c`) compares the stored id against every entry and
flags the match with `submenu.selected`. `GUI_OP_APPEND_MENU` turns that flag into
`menu->remindLast`. Upstream chains it as an `else if` to the "first subitem in list" case:

```c
if (!item->menu.menu->submenu) {        // first subitem in list
    ...
} else if (item->submenu.selected) {    // remember last played game feature
    ...
    item->menu.menu->remindLast = 1;
```

When the remembered game *is* the first item appended, the first branch consumes it and
`remindLast` is never raised. `GUI_OP_SORT` then runs:

```c
if (!item->menu.menu->remindLast)
    item->menu.menu->current = item->menu.menu->submenu;
```

and the cursor is put back on the head of the alphabetically sorted list. The same branch
also holds the `DisableCron = 0` that releases the auto start counter, which is why the
countdown was missing for that one game — a useful way to tell this bug apart from a
genuine id mismatch.

Index 0 is not something the user can see or influence: `sbReadList()` stores the `ul.cfg`
entries first, and `scanForISO()` prepends each file while walking the directory, so the
last name `readdir()` returns is the one that lands first.

The fix splits the chain into two independent `if`s. For every other entry nothing changes;
for index 0 the second block re-assigns the same node and raises `remindLast`.

## Related gaps, not fixed here

- The **Favourites** tab never restores the last played game at all. It is built by
  `updateFavouritesMenu()` (`src/favsupport.c`), which hardcodes `submenu.selected = 0` and
  never consults the stored id.
- wOPL always opens the tab of `gDefaultDevice`. If the game was played from another
  device, the selection is applied correctly — just on a tab you are not looking at.

## Upstreamable

Yes, and it was: see PR #435. If upstream merges it, drop this patch on the next rebase.

## How to revert

`git apply -R customs/patches/gui.c.remember-last.patch`.
