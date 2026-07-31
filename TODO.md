# TODO

Things we deliberately kicked down the road. Written 2026-07-31.

Background and rules live in `CLAUDE.md` — especially the sudo/faillock warning
(print root commands, don't run them) and the fact that `ivy` is a disk that has
outlived two computers.

---

## 1. The lil popup — searchable Unicode

**Status: to be designed in its own chat. This is the main event.**

The ask, in Astrid's words: *"Unicode accessible by search in a lil popup."*

### What it needs to do

- Pop up instantly on a keybind, keyboard-driven, no mouse
- Search Unicode **by name/description** — type `heart`, get `♡ ❤ 💖`; type
  `arrow`, get `→ ⇒ ↦`
- Insert the pick into whatever window has focus, or put it on the clipboard
- Be fast on a 1.6GHz Braswell Pentium, which is the real constraint

### What we already worked out

The original plan was a custom daemon holding a Qt widget. Two findings from
this chat that change that:

- **Qt's cost is process startup, not rendering.** Loading Qt6 + fontconfig cold
  is a few hundred ms here, which is too slow for something hit constantly.
  A *resident* daemon that show/hides a prebuilt window avoids this — which is
  why the daemon instinct was right. But `rofi`/`dmenu` are small C programs
  that cold-start in tens of ms and need no daemon at all.
- **The way to splash a window on X11 is an override-redirect window** — a flag
  saying "WM, don't manage me". Instant, undecorated, exact coordinates, no
  focus negotiation. It's what dmenu does; in Qt it's
  `Qt::X11BypassWindowManagerHint | Qt::FramelessWindowHint`. This matters
  *specifically* because blackbox predates many `_NET_WM_*` hints, so anything
  relying on WM cooperation is a gamble. Override-redirect sidesteps the WM.

**Emoji fonts are already solved** — `noto-fonts-emoji` is installed and
`fc-match emoji` resolves to `NotoColorEmoji.ttf`. Not a blocker.

### rofimoji is probably the substrate (`extra/rofimoji`, 2 pkgs, 3.4M)

It is genuinely scriptable and does most of this already:

- `--action` takes `type`, `copy`, `clipboard`, `type-numerical`, `unicode`,
  `copy-unicode`, `print`, `menu` — **and they chain**. `print` goes to stdout,
  so it composes with anything.
- `--files` accepts **custom CSV** files: one character per line, then a space,
  then the description. Full path. So our own sets are a supported feature, not
  a hack.
- Ships sets for emoji, math, Nerd Font, Font Awesome 6, Gitmoji, Kaomoji, HTML
  named character references, CJK.
- `--selector` on X.org: `rofi`, `bemenu`, `dmenu`. `--typer xdotool` and
  `--clipboarder xclip` — **both already installed here.**
- Also `--prompt`, `--selector-args`, `--max-recent` (0-10), `--skin-tone`.

### Open design questions for the next chat

1. **Scope of "Unicode".** rofimoji's sets are curated lists, not all ~150k
   codepoints. Searching *all* of Unicode by name means building a set from
   `UnicodeData.txt` (field 1 is the official name). Do we want the whole thing,
   or curated sets that actually fit on screen? Probably: curated by default,
   full set behind a flag.
2. **Selector.** `rofi` (1.1M, 2 pkgs, richest features — custom keybinds and
   multi-select only work with rofi) vs `dmenu` (51K, needs a patch for most
   niceties). Given the CPU, both are fine cold; rofi is the better base.
3. **Insert method.** Typing via `xdotool` avoids the clipboard entirely, which
   dodges the X11 ownership race described in `CLAUDE.md`. Probably the default,
   with copy as a fallback for apps that don't take synthetic keystrokes.
4. **Does it need to be resident at all?** If rofi cold-start is genuinely
   instant here, the whole daemon idea can be dropped. **Measure before
   building** — this is a "is the slow thing actually slow" question, and the
   answer is a `time` invocation away.
5. **Recent/frequent tracking.** `--max-recent` gives a little of this for free.
6. **Does it absorb `bin/{heart,supson,endash,emdash,♡}`?** Those are five
   scripts that each echo one glyph into `xclip -f`, leaving a resident xclip
   behind every time (see clipboard notes in `CLAUDE.md`). A custom CSV file
   plus one keybind replaces all five.

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
