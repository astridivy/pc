# TODO

Things we deliberately kicked down the road. Written 2026-07-31.

Background and rules live in `CLAUDE.md` — especially the sudo/faillock warning
(print root commands, don't run them) and the fact that `ivy` is a disk that has
outlived two computers.

---

## 1. dotkey — searchable Unicode popup — **BUILT 2026-07-31**

*"win-key dot, but mangled a bit."* Bound to **Mod4-period**, the same chord
Windows uses. Works end to end: press it, type a name, hit enter, the glyph
lands in whatever you were typing in.

- `bin/dotkeyd` — resident daemon: the index, the popup, the delivery
- `bin/dotkey` — tiny shell client that pokes the daemon through a fifo
- `.config/dotkey/custom.tsv` — own glyphs, ranked above all of Unicode
- `.bbkeysrc` holds the binding (now tracked and symlinked out); `.xinitrc`
  starts the daemon at login

Searches **all 148,875 named codepoints**, straight out of python's own
`unicodedata` (16.0.0) — no `UnicodeData.txt` download, no curated subset. The
open question about scope answered itself: with CJK and Hangul pushed down the
ranking, the full set is *better* than a curated one, because nothing is
missing and nothing is in the way. See `CLAUDE.md` for the design notes that
matter.

Answers to the questions this file asked before it was built:

1. **Scope** — the whole thing, ~149k. Bulk algorithmic names (CJK, Hangul,
   Tangut...) rank last, so they never crowd a real answer.
2. **Selector** — none of them. `rofi`, `dmenu` and `rofimoji` are all *not
   installed*, and installing needs root. A resident GTK daemon needs nothing
   new and is faster than any cold start could be.
3. **Insert method** — **the assumption here was wrong.** Typing via `xdotool`
   is the *un*reliable option on this box, not the safe one: 1 success in 8.
   Clipboard + a per-app paste chord is the reliable path. Details in
   `CLAUDE.md`.
4. **Resident?** — yes, and measurably so. GTK's import alone is 1.64s here.
5. **Recents** — done, frequency-ranked, in `~/.cache/dotkey/recent.json`.
6. **Absorbs the five glyph scripts?** — the *content* does: `heart`, `supson`,
   `endash`, `emdash` and the shrug are all in `custom.tsv` and rank first.
   `bin/{heart,supson,endash,emdash,♡}` are still there and still work; deleting
   them is a separate call, since `.blackbox/menu` may reference them.

### Still open on dotkey

- No **skin-tone** or variation-selector handling.
- The popup is fixed at 10 rows and does not scroll; more matches exist than
  are shown. Fine in practice, but paging would be nice.
- `--type` mode is kept as a fallback and is genuinely unreliable — see the
  measurement in `CLAUDE.md` before trying to "fix" it.

---

## 2. Clipboard

- **Install a clipboard manager.** Nothing arbitrates selection ownership right
  now, which is the cause of alacritty's intermittent
  `Unable to store text in clipboard`. Recommended: `copyq` (`extra/`, 9 pkgs;
  `qt6-base` already present). It is a resident daemon with a real query API —
  `copyq clipboard`, `copyq selection`, `copyq read 0`, `copyq add`,
  `copyq size`, `copyq eval`. Lighter alternatives: `clipmenu` (4 pkgs, ~2M,
  history is plain files) or `clipnotify` (14K) to build our own.
- **CopyQ's `menu(tabName[, max[, x, y]])` + `paste()` is a picker for free** —
  worth knowing when designing the popup above; it's the "daemon pops a Qt
  widget" design already built. A `glyphs` tab may be the cheapest version of
  item 1.
- **Wire up `g:clipboard` in `.vimrc`.** Arch's vim is built `-clipboard -X11
  -xterm_clipboard`, so `set clipboard=unnamedplus` (line 11) has never done
  anything — `has('clipboard_working')` is 0. Vim 9.2 has
  `+clipboard_provider`, so a `g:clipboard` dict pointed at `xclip` would make
  `"+y` work natively. Keep `:XClip` and the visual `Y`/`D`/`X` maps regardless
  — they are load-bearing today.

---

## 3. Razer Cynosa Chroma

The Logitech board was stolen; `keyledsd` is now dead weight. The Cynosa is
**per-key addressable** (OpenRazer `MATRIX_DIMS = [6, 22]`) and supports wave,
static, spectrum, reactive, breath, starlight, ripple, and full custom per-key.
The DeathAdder Essential mouse (`1532:0098`) is supported by the same daemon.

- **Finish activating it.** `openrazer-daemon` and `linux-headers` are
  installed, but no razer module is loaded and there is **no `plugdev` group**:

  ```bash
  sudo gpasswd -a astrid plugdev     # creates membership; group may need creating
  sudo modprobe razerkbd
  ```

  Then log out and back in for the group. Verify with
  `python -c "import openrazer.client as c; print(c.DeviceManager().devices)"`.
- **Rebuild the per-app profiles.** `python-openrazer` gives a real API, so
  keyledsd's idea — match on window class, set an effect — is a `bin/` script.
  This is the thing actually worth having back.
- **Retire the keyledsd relics**: `.config/keyledsd.conf`, `bin/keyleds_toggle`,
  and the `RGB Keyboard LEDs` entry in `.blackbox/menu`, which currently
  launches something that silently does nothing.

---

## 4. System

- **`sudo resize2fs /dev/sda1`** — still outstanding, still ~38G of the
  partition unreachable. One online command. See `CLAUDE.md`.
- **Set the wifi regulatory country.** `iw reg get` reports `country 00`, the
  conservative world domain, which limits channels and TX power.
  `wireless-regdb` is installed now, so the database is there; nothing sets a
  country.

*(Done this session, don't redo: fallback initramfs enabled and built,
`intel-ucode` installed, `grub-mkconfig` run — grub.cfg now has 3 ucode
references — and `wireless-regdb` installed.)*

---

## 5. Repo hygiene

- **`origin/serverside` is nearly exhausted.** Two passes are merged. What's
  left is mostly serverside being *older* than master. Genuinely un-reviewed:
  `bin/maeusic` (serverside has `cadence-jackmeter` and
  `carla-single ~/doc/baby_grand.carxp` that master dropped — a music-rig
  preference call), and `.blackbox/menu`'s Enable/Disable Laptop Monitor
  entries, which reference `LVDS-1` and would need `eDP1` to work on the Dell.
  `.config/keyledsd.conf`'s four extra effects are now moot. **Diff two-dot**
  (`git diff master origin/serverside`), never three-dot — see `CLAUDE.md`.
- **`etc/default/grub` has drifted from live**: repo says `GRUB_DEFAULT=0` /
  `GRUB_TIMEOUT=1`, live says `saved` / `2`. Expected for `etc/` staging, but
  worth reconciling.
- **`bell/.sequence`** is transient runtime state written into a tracked
  directory; it flickers in and out of `git status`. Probably wants a
  `.gitignore` line.
- **`~/src/diet-vhost` and `~/src/maitre-d`** declare dependencies but have no
  `node_modules` — they need an `npm install` before they'll run.
